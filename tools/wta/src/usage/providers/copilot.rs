use super::{
    PrivateUsagePolicy, ProviderContextUsage, ProviderUsageAdapter, ProviderUsageContribution,
    ProviderUsageError, ProviderUsageInput, ProviderUsageMetric, ProviderUsageRequest,
};

const COPILOT_REPORTER_ID: &str = "Copilot";
const CONTEXT_SCHEMA_ID: &str = "copilot.cli.context.v1.0.77";
const USAGE_SCHEMA_ID: &str = "copilot.cli.usage.v1.0.77";

fn schema_error(schema_id: &'static str, class: &'static str) -> ProviderUsageError {
    ProviderUsageError {
        family_id: crate::agent_registry::COPILOT_AGENT_ID,
        schema_id,
        class,
    }
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

fn parse_context_output(text: &str) -> Result<ProviderUsageContribution, ProviderUsageError> {
    let line = text
        .lines()
        .find(|line| line.contains(" tokens (") && line.contains('/'))
        .ok_or_else(|| schema_error(CONTEXT_SCHEMA_ID, "schema_mismatch"))?;
    let (before_tokens, after_tokens) = line
        .split_once(" tokens (")
        .ok_or_else(|| schema_error(CONTEXT_SCHEMA_ID, "schema_mismatch"))?;
    let ratio = before_tokens
        .split_whitespace()
        .last()
        .ok_or_else(|| schema_error(CONTEXT_SCHEMA_ID, "schema_mismatch"))?;
    let (used_text, size_text) = ratio
        .split_once('/')
        .ok_or_else(|| schema_error(CONTEXT_SCHEMA_ID, "schema_mismatch"))?;
    let percent_text = after_tokens
        .strip_suffix("%)")
        .ok_or_else(|| schema_error(CONTEXT_SCHEMA_ID, "schema_mismatch"))?;
    let used = parse_abbreviated_count(used_text)
        .ok_or_else(|| schema_error(CONTEXT_SCHEMA_ID, "invalid_count"))?;
    let size = parse_abbreviated_count(size_text)
        .ok_or_else(|| schema_error(CONTEXT_SCHEMA_ID, "invalid_count"))?;
    let reported_percent = percent_text
        .parse::<u64>()
        .map_err(|_| schema_error(CONTEXT_SCHEMA_ID, "invalid_percent"))?;

    Ok(ProviderUsageContribution {
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

fn parse_usage_output(text: &str) -> Result<ProviderUsageContribution, ProviderUsageError> {
    let requests = text
        .lines()
        .find_map(|line| line.trim().strip_prefix("Requests: "))
        .ok_or_else(|| schema_error(USAGE_SCHEMA_ID, "schema_mismatch"))?;
    let (amount_text, remainder) = requests
        .split_once(' ')
        .ok_or_else(|| schema_error(USAGE_SCHEMA_ID, "schema_mismatch"))?;
    let _ = parse_decimal_text(amount_text)
        .ok_or_else(|| schema_error(USAGE_SCHEMA_ID, "invalid_amount"))?;
    let unit_id = remainder
        .rsplit_once(" (")
        .map(|(unit, _)| unit)
        .ok_or_else(|| schema_error(USAGE_SCHEMA_ID, "schema_mismatch"))?;
    if !matches!(unit_id, "AI Unit" | "AI Units" | "AI Credit" | "AI Credits") {
        return Err(schema_error(USAGE_SCHEMA_ID, "untrusted_unit"));
    }

    Ok(ProviderUsageContribution {
        metrics: vec![ProviderUsageMetric {
            metric_id: "github.copilot.ai_units".to_string(),
            value_decimal_text: amount_text.to_string(),
            limit_decimal_text: None,
            unit_id: unit_id.to_string(),
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
            } => parse_context_output(text),
            ProviderUsageInput::ProviderCommandOutput {
                command: "/usage",
                text,
            } => parse_usage_output(text),
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
    const USAGE_OUTPUT: &str = "Session Usage\n\nChanges: +0 -0\nRequests: 2 AI Units (53s)\nTokens: input 79.7k, output 16, cached 39.8k";

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
    }

    #[test]
    fn parses_verified_usage_command_ai_units_only() {
        let contribution = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/usage",
                    text: USAGE_OUTPUT,
                },
            })
            .expect("verified Copilot usage output should parse");

        assert!(contribution.context.is_none());
        assert!(contribution.cost.is_none());
        assert_eq!(contribution.metrics.len(), 1);
        assert_eq!(contribution.metrics[0].metric_id, "github.copilot.ai_units");
        assert_eq!(contribution.metrics[0].value_decimal_text, "2");
        assert_eq!(contribution.metrics[0].unit_id, "AI Units");

        let fractional = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/usage",
                    text: "Session Usage\nRequests: 0.33 AI Credits (1s)\nTokens: input 1, output 1, cached 0",
                },
            })
            .expect("fractional Copilot usage should preserve provider precision");
        assert_eq!(fractional.metrics[0].value_decimal_text, "0.33");
        assert_eq!(fractional.metrics[0].unit_id, "AI Credits");
    }

    #[test]
    fn rejects_lookalike_reporters_and_schema_drift() {
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

        let error = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/usage",
                    text: "Session Usage\nRequests changed format",
                },
            })
            .expect_err("trusted reporter schema drift must fail closed");
        assert_eq!(error.family_id, crate::agent_registry::COPILOT_AGENT_ID);
        assert_eq!(error.class, "schema_mismatch");

        let malformed_amount = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("Copilot"),
                input: ProviderUsageInput::ProviderCommandOutput {
                    command: "/usage",
                    text: "Session Usage\nRequests: 2. AI Units (1s)",
                },
            })
            .expect_err("malformed amount must fail closed");
        assert_eq!(malformed_amount.class, "invalid_amount");
    }
}
