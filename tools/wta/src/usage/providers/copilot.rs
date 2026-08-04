use super::{
    PrivateUsagePolicy, ProviderContextUsage, ProviderUsageAdapter, ProviderUsageContribution,
    ProviderUsageError, ProviderUsageInput, ProviderUsageMetric, ProviderUsageRequest,
};

const COPILOT_REPORTER_ID: &str = "Copilot";
const POST_TURN_COMMANDS: &[&str] = &["/context", "/usage"];

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

fn try_parse_usage_output(text: &str) -> Option<ProviderUsageContribution> {
    let requests = text
        .lines()
        .find_map(|line| line.trim().strip_prefix("Requests: "))?;
    let (amount_text, remainder) = requests.split_once(' ')?;
    let (_, numerator, _) = parse_decimal_text(amount_text)?;
    if numerator == 0 {
        return None;
    }
    let unit = remainder.rsplit_once(" (").map(|(unit, _)| unit)?;
    if !matches!(unit, "AI Unit" | "AI Units" | "AI Credit" | "AI Credits") {
        return None;
    }

    Some(ProviderUsageContribution {
        metrics: vec![ProviderUsageMetric {
            metric_id: "github.copilot.ai_usage".to_string(),
            display_kind: crate::usage::UsageDisplayKind::Billing,
            value_decimal_text: amount_text.to_string(),
            limit_decimal_text: None,
            unit_id: unit.to_string(),
            unit_display_text: unit.to_string(),
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
        PrivateUsagePolicy::VerifiedCommandProbe
    }

    fn trusted_reporter_ids(&self) -> &'static [&'static str] {
        &[COPILOT_REPORTER_ID]
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
                command: "/usage",
                text,
            } => Ok(try_parse_usage_output(text).unwrap_or_default()),
            _ => Ok(ProviderUsageContribution::default()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::usage::providers::ProviderUsageInput;

    const CONTEXT_OUTPUT: &str =
        "Context Usage\n\nclaude-sonnet-5 · 30k/264k tokens (11%)\nSystem Prompt 18.0k (7%)";
    const USAGE_OUTPUT: &str = "Session Usage\n\nChanges: +0 -0\nRequests: 2 AI Credits (19s)\nTokens: input 24.7k, output 22, cached 0, reasoning 13";

    #[test]
    fn uses_context_and_usage_commands() {
        assert_eq!(ADAPTER.post_turn_commands(), &["/context", "/usage"]);
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
    fn tries_positive_usage_and_hides_nonpositive_or_invalid_values() {
        let contribution = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/usage",
                    text: USAGE_OUTPUT,
                },
            })
            .expect("positive Copilot /usage output should parse");

        assert!(contribution.context.is_none());
        assert!(contribution.cost.is_none());
        assert_eq!(contribution.metrics.len(), 1);
        assert_eq!(contribution.metrics[0].metric_id, "github.copilot.ai_usage");
        assert_eq!(
            contribution.metrics[0].display_kind,
            crate::usage::UsageDisplayKind::Billing
        );
        assert_eq!(contribution.metrics[0].value_decimal_text, "2");
        assert_eq!(contribution.metrics[0].unit_id, "AI Credits");
        assert_eq!(contribution.metrics[0].unit_display_text, "AI Credits");

        let fractional = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/usage",
                    text: "Session Usage\nRequests: 0.33 AI Credits (1s)",
                },
            })
            .expect("positive fractional Copilot /usage output should parse");
        assert_eq!(fractional.metrics[0].value_decimal_text, "0.33");

        for output in [
            "Session Usage\nRequests: 0 AI Units (1s)",
            "Session Usage\nRequests: -1 AI Credits (1s)",
            "Session Usage\nRequests: unavailable",
            "Session Usage\nRequests: 2 Requests (1s)",
        ] {
            let hidden = ADAPTER
                .extract_private_usage(ProviderUsageRequest {
                    reporter_id: Some("Copilot"),
                    input: ProviderUsageInput::ProviderCommandOutput {
                        command: "/usage",
                        text: output,
                    },
                })
                .expect("invalid Copilot /usage output should be omitted");
            assert_eq!(hidden, ProviderUsageContribution::default());
        }
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
