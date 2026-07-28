use super::{
    PrivateUsagePolicy, ProviderUsageAdapter, ProviderUsageContribution, ProviderUsageError,
    ProviderUsageRequest,
};

pub(super) struct GeminiUsageAdapter;

pub(super) static ADAPTER: GeminiUsageAdapter = GeminiUsageAdapter;
const SCHEMA_ID: &str = "gemini-cli.acp.prompt-response-meta.quota.v1";

impl ProviderUsageAdapter for GeminiUsageAdapter {
    fn family_id(&self) -> &'static str {
        crate::agent_registry::GEMINI_AGENT_ID
    }

    fn private_usage_policy(&self) -> PrivateUsagePolicy {
        PrivateUsagePolicy::VerifiedPrivate
    }

    fn trusted_reporter_ids(&self) -> &'static [&'static str] {
        &["gemini-cli"]
    }

    fn extract_private_usage(
        &self,
        request: ProviderUsageRequest<'_>,
    ) -> Result<ProviderUsageContribution, ProviderUsageError> {
        if !request
            .reporter_id
            .is_some_and(|reporter| self.trusted_reporter_ids().contains(&reporter))
        {
            return Ok(ProviderUsageContribution::default());
        }
        let super::ProviderUsageInput::PromptResponseMeta(meta) = request.input else {
            return Ok(ProviderUsageContribution::default());
        };
        let token_count = meta
            .get("quota")
            .and_then(|quota| quota.get("token_count"))
            .ok_or_else(invalid_quota)?;
        let input_tokens = token_count
            .get("input_tokens")
            .and_then(serde_json::Value::as_u64)
            .ok_or_else(invalid_quota)?;
        let output_tokens = token_count
            .get("output_tokens")
            .and_then(serde_json::Value::as_u64)
            .ok_or_else(invalid_quota)?;

        Ok(ProviderUsageContribution {
            input_tokens: Some(input_tokens),
            output_tokens: Some(output_tokens),
            ..Default::default()
        })
    }
}

fn invalid_quota() -> ProviderUsageError {
    ProviderUsageError {
        family_id: crate::agent_registry::GEMINI_AGENT_ID,
        schema_id: SCHEMA_ID,
        class: "invalid_token_count",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::usage::providers::ProviderUsageInput;

    fn verified_meta() -> serde_json::Value {
        serde_json::json!({
            "quota": {
                "token_count": {
                    "input_tokens": 10_270,
                    "output_tokens": 9
                },
                "model_usage": [{
                    "model": "gemini-3.5-flash",
                    "token_count": {
                        "input_tokens": 10_270,
                        "output_tokens": 9
                    }
                }]
            }
        })
    }

    #[test]
    fn extracts_verified_gemini_prompt_response_tokens() {
        let meta = verified_meta();
        let contribution = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("gemini-cli"),
                input: ProviderUsageInput::PromptResponseMeta(&meta),
            })
            .expect("verified Gemini quota");

        assert_eq!(contribution.input_tokens, Some(10_270));
        assert_eq!(contribution.output_tokens, Some(9));
        assert!(contribution.context.is_none());
        assert!(contribution.cost.is_none());
        assert!(contribution.metrics.is_empty());
    }

    #[test]
    fn rejects_untrusted_reporter_and_non_prompt_sources() {
        let meta = verified_meta();
        for reporter_id in [None, Some("gemini"), Some("lookalike-gemini-cli")] {
            assert_eq!(
                ADAPTER
                    .extract_private_usage(ProviderUsageRequest {
                        reporter_id,
                        input: ProviderUsageInput::PromptResponseMeta(&meta),
                    })
                    .expect("untrusted reporter is ignored"),
                ProviderUsageContribution::default()
            );
        }
        assert_eq!(
            ADAPTER
                .extract_private_usage(ProviderUsageRequest {
                    reporter_id: Some("gemini-cli"),
                    input: ProviderUsageInput::SessionUpdateMeta(&meta),
                })
                .expect("wrong source is ignored"),
            ProviderUsageContribution::default()
        );
    }

    #[test]
    fn rejects_malformed_verified_quota() {
        for meta in [
            serde_json::json!({}),
            serde_json::json!({ "quota": { "token_count": { "input_tokens": -1, "output_tokens": 9 } } }),
            serde_json::json!({ "quota": { "token_count": { "input_tokens": 10, "output_tokens": "9" } } }),
        ] {
            assert!(
                ADAPTER
                    .extract_private_usage(ProviderUsageRequest {
                        reporter_id: Some("gemini-cli"),
                        input: ProviderUsageInput::PromptResponseMeta(&meta),
                    })
                    .is_err()
            );
        }
    }
}
