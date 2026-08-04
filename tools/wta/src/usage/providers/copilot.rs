use super::{
    PrivateUsagePolicy, ProviderContextUsage, ProviderLocalUsageCursor, ProviderUsageAdapter,
    ProviderUsageContribution, ProviderUsageError, ProviderUsageInput, ProviderUsageMetric,
    ProviderUsageRequest,
};

const COPILOT_REPORTER_ID: &str = "Copilot";
// Internal shape version, not a Copilot CLI release number. Compatible CLI
// releases continue to work; missing fields simply produce no contribution.
const SESSION_USAGE_SCHEMA_ID: &str = "copilot.cli.session_usage_checkpoint.v1";
const NANO_AIU_PER_AIC: u64 = 1_000_000_000;
const POST_TURN_COMMANDS: &[&str] = &["/context"];

fn session_events_path_in(home: &std::path::Path, session_id: &str) -> Option<std::path::PathBuf> {
    let segment = std::path::Path::new(session_id);
    if segment.file_name() != Some(std::ffi::OsStr::new(session_id))
        || matches!(session_id, "." | "..")
    {
        return None;
    }
    Some(
        home.join(".copilot")
            .join("session-state")
            .join(session_id)
            .join("events.jsonl"),
    )
}

fn parse_decimal_text(text: &str) -> Option<(&str, u128, u128)> {
    if text.is_empty() || text.len() > 32 {
        return None;
    }
    let (whole, fraction) = text.split_once('.').unwrap_or((text, ""));
    if whole.is_empty()
        || (text.contains('.') && fraction.is_empty())
        || !whole.bytes().all(|byte| byte.is_ascii_digit())
        || !fraction.bytes().all(|byte| byte.is_ascii_digit())
    {
        return None;
    }
    let denominator = 10u128.checked_pow(fraction.len().try_into().ok()?)?;
    let whole_value = whole.parse::<u128>().ok()?;
    let fraction_value = if fraction.is_empty() {
        0
    } else {
        fraction.parse::<u128>().ok()?
    };
    let numerator = whole_value
        .checked_mul(denominator)?
        .checked_add(fraction_value)?;
    Some((text, numerator, denominator))
}

fn parse_abbreviated_count(text: &str) -> Option<u64> {
    let (number, multiplier) = match text.as_bytes().last().copied() {
        Some(b'k' | b'K') => (&text[..text.len() - 1], 1_000u128),
        Some(b'm' | b'M') => (&text[..text.len() - 1], 1_000_000u128),
        _ => (text, 1u128),
    };
    let (_, numerator, denominator) = parse_decimal_text(number)?;
    let scaled = numerator.checked_mul(multiplier)?;
    if scaled % denominator != 0 {
        return None;
    }
    u64::try_from(scaled / denominator).ok()
}

fn try_parse_context_output(text: &str) -> Option<ProviderUsageContribution> {
    let line = text
        .lines()
        .find(|line| line.contains(" tokens (") && line.contains('/'))?;
    let (before_tokens, after_tokens) = line.split_once(" tokens (")?;
    let ratio = before_tokens.split_whitespace().last()?;
    let (used_text, size_text) = ratio.split_once('/')?;
    let percent_text = after_tokens.strip_suffix("%)")?;
    let used = parse_abbreviated_count(used_text)?;
    let size = parse_abbreviated_count(size_text)?;
    let reported_percent = percent_text.parse::<u64>().ok()?;

    Some(ProviderUsageContribution {
        context: Some(ProviderContextUsage {
            used,
            size,
            used_display_text: used_text.to_string(),
            size_display_text: size_text.to_string(),
            reported_percent,
        }),
        ..Default::default()
    })
}

fn nano_aiu_decimal_text(total_nano_aiu: u64) -> String {
    let whole = total_nano_aiu / NANO_AIU_PER_AIC;
    let remainder = total_nano_aiu % NANO_AIU_PER_AIC;
    if remainder == 0 {
        return whole.to_string();
    }
    let fraction = format!("{remainder:09}").trim_end_matches('0').to_string();
    format!("{whole}.{fraction}")
}

fn try_parse_session_usage_event(event: &serde_json::Value) -> Option<ProviderUsageContribution> {
    if event.get("type").and_then(serde_json::Value::as_str) != Some("session.usage_checkpoint") {
        return None;
    }
    let total_nano_aiu = event
        .get("data")
        .and_then(|data| data.get("totalNanoAiu"))
        .and_then(serde_json::Value::as_u64)?;

    Some(ProviderUsageContribution {
        metrics: vec![ProviderUsageMetric {
            metric_id: "github.copilot.ai_credits".to_string(),
            display_kind: crate::usage::UsageDisplayKind::Billing,
            value_decimal_text: nano_aiu_decimal_text(total_nano_aiu),
            limit_decimal_text: None,
            unit_id: "AIC".to_string(),
            unit_display_text: "AIC".to_string(),
        }],
        ..Default::default()
    })
}

pub(super) struct CopilotUsageAdapter;

pub(super) static ADAPTER: CopilotUsageAdapter = CopilotUsageAdapter;

impl ProviderUsageAdapter for CopilotUsageAdapter {
    fn family_id(&self) -> &'static str {
        crate::agent_registry::COPILOT_AGENT_ID
    }

    fn private_usage_policy(&self) -> PrivateUsagePolicy {
        PrivateUsagePolicy::VerifiedLocalSources
    }

    fn trusted_reporter_ids(&self) -> &'static [&'static str] {
        &[COPILOT_REPORTER_ID]
    }

    fn begin_local_usage(&self, session_id: &str) -> Option<ProviderLocalUsageCursor> {
        let home = std::env::var_os("USERPROFILE").map(std::path::PathBuf::from)?;
        let path = session_events_path_in(&home, session_id)?;
        Some(ProviderLocalUsageCursor::jsonl(
            path,
            crate::agent_registry::COPILOT_AGENT_ID,
            SESSION_USAGE_SCHEMA_ID,
        ))
    }

    fn post_turn_commands(&self) -> &'static [&'static str] {
        POST_TURN_COMMANDS
    }

    fn extract_private_usage(
        &self,
        request: ProviderUsageRequest<'_>,
    ) -> Result<ProviderUsageContribution, ProviderUsageError> {
        if request.reporter_id != Some(COPILOT_REPORTER_ID) {
            return Ok(ProviderUsageContribution::default());
        }
        match request.input {
            ProviderUsageInput::ProviderCommandOutput {
                command: "/context",
                text,
            } => Ok(try_parse_context_output(text).unwrap_or_default()),
            ProviderUsageInput::ProviderCommandOutput {
                command: "/usage", ..
            } => Ok(ProviderUsageContribution::default()),
            ProviderUsageInput::ProviderSessionEvent(event) => {
                Ok(try_parse_session_usage_event(event).unwrap_or_default())
            }
            _ => Ok(ProviderUsageContribution::default()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::usage::providers::ProviderUsageInput;
    use std::path::{Path, PathBuf};

    const CONTEXT_OUTPUT: &str =
        "Context Usage\n\nclaude-sonnet-5 · 30k/264k tokens (11%)\nSystem Prompt 18.0k (7%)";
    const USAGE_OUTPUT: &str = "Session Usage\n\nChanges: +0 -0\nRequests: 1 AI Units (19s)\nTokens: input 24.7k, output 22, cached 0, reasoning 13";

    #[test]
    fn owns_local_session_source_and_post_turn_commands() {
        assert_eq!(
            SESSION_USAGE_SCHEMA_ID,
            "copilot.cli.session_usage_checkpoint.v1"
        );
        assert_eq!(ADAPTER.post_turn_commands(), &["/context"]);
        assert_eq!(
            session_events_path_in(Path::new(r"C:\Users\u"), "session-1"),
            Some(PathBuf::from(
                r"C:\Users\u\.copilot\session-state\session-1\events.jsonl"
            ))
        );
        assert_eq!(
            session_events_path_in(Path::new(r"C:\Users\u"), r"..\escape"),
            None
        );
    }

    #[test]
    fn parses_verified_context_command_output() {
        let contribution = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/context",
                    text: CONTEXT_OUTPUT,
                },
            })
            .expect("verified Copilot context output should parse");

        let context = contribution.context.expect("context contribution");
        assert_eq!(context.used, 30_000);
        assert_eq!(context.size, 264_000);
        assert_eq!(context.used_display_text, "30k");
        assert_eq!(context.size_display_text, "264k");
        assert_eq!(context.reported_percent, 11);
        assert!(contribution.metrics.is_empty());

        let future_compatible = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/context",
                    text: "Context Usage\n\nfuture-model · 25k/400k tokens (6%)\nNew Section 1k (<1%)",
                },
            })
            .expect("compatible future context shape should still parse");
        assert_eq!(future_compatible.context.expect("context").size, 400_000);
    }

    #[test]
    fn parses_real_session_checkpoint_aic_and_ignores_usage_request_count() {
        let contribution = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/usage",
                    text: USAGE_OUTPUT,
                },
            })
            .expect("Copilot /usage output should be ignored");

        assert!(contribution.context.is_none());
        assert!(contribution.cost.is_none());
        assert!(contribution.metrics.is_empty());

        // Real Copilot CLI 1.0.77 checkpoint from session
        // 6106fe85-60d4-41d2-9154-091ab673c428 after "Bonjour".
        let checkpoint = serde_json::json!({
            "type": "session.usage_checkpoint",
            "data": {
                "totalNanoAiu": 7_553_900_000u64,
                "totalPremiumRequests": 1
            }
        });
        let contribution = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderSessionEvent(&checkpoint),
            })
            .expect("real Copilot checkpoint should parse");
        assert_eq!(
            contribution.metrics[0].metric_id,
            "github.copilot.ai_credits"
        );
        assert_eq!(contribution.metrics[0].value_decimal_text, "7.5539");
        assert_eq!(contribution.metrics[0].unit_id, "AIC");
    }

    #[test]
    fn ignores_impostor_reporters_and_missing_future_fields() {
        for reporter_id in [None, Some("copilot"), Some("GitHub Copilot")] {
            let contribution = ADAPTER
                .extract_private_usage(ProviderUsageRequest {
                    reporter_id,
                    input: ProviderUsageInput::ProviderCommandOutput {
                        command: "/usage",
                        text: USAGE_OUTPUT,
                    },
                })
                .expect("untrusted reporter should be ignored");
            assert_eq!(contribution, ProviderUsageContribution::default());
        }

        let missing_checkpoint_field = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderSessionEvent(&serde_json::json!({
                    "type": "session.usage_checkpoint",
                    "data": { "totalNanoAiu": "not-a-number" }
                })),
            })
            .expect("missing future field should be omitted");
        assert_eq!(
            missing_checkpoint_field,
            ProviderUsageContribution::default()
        );

        let missing_context_shape = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/context",
                    text: "A future context format without the current ratio line",
                },
            })
            .expect("missing future context shape should be omitted");
        assert_eq!(missing_context_shape, ProviderUsageContribution::default());
    }
}
