use super::{
    PrivateUsagePolicy, ProviderUsageAdapter, ProviderUsageContribution, ProviderUsageError,
    ProviderUsageRequest,
};

pub(super) struct GeminiUsageAdapter;

pub(super) static ADAPTER: GeminiUsageAdapter = GeminiUsageAdapter;

impl ProviderUsageAdapter for GeminiUsageAdapter {
    fn family_id(&self) -> &'static str {
        crate::agent_registry::GEMINI_AGENT_ID
    }

    fn private_usage_policy(&self) -> PrivateUsagePolicy {
        PrivateUsagePolicy::StandardAcpOnly
    }

    fn trusted_reporter_ids(&self) -> &'static [&'static str] {
        &[]
    }

    fn extract_private_usage(
        &self,
        request: ProviderUsageRequest<'_>,
    ) -> Result<ProviderUsageContribution, ProviderUsageError> {
        super::no_verified_private_usage(request)
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
    fn ignores_gemini_private_prompt_response_tokens() {
        let meta = verified_meta();
        let contribution = ADAPTER
            .extract_private_usage(ProviderUsageRequest {
                reporter_id: Some("gemini-cli"),
                input: ProviderUsageInput::PromptResponseMeta(&meta),
            })
            .expect("Gemini private quota is ignored");

        assert_eq!(contribution, ProviderUsageContribution::default());
        assert_eq!(
            ADAPTER.private_usage_policy(),
            PrivateUsagePolicy::StandardAcpOnly
        );
        assert!(ADAPTER.trusted_reporter_ids().is_empty());
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
    fn malformed_gemini_private_quota_is_ignored() {
        for meta in [
            serde_json::json!({}),
            serde_json::json!({ "quota": { "token_count": { "input_tokens": -1, "output_tokens": 9 } } }),
            serde_json::json!({ "quota": { "token_count": { "input_tokens": 10, "output_tokens": "9" } } }),
        ] {
            assert_eq!(
                ADAPTER
                    .extract_private_usage(ProviderUsageRequest {
                        reporter_id: Some("gemini-cli"),
                        input: ProviderUsageInput::PromptResponseMeta(&meta),
                    })
                    .expect("Gemini private quota is ignored"),
                ProviderUsageContribution::default()
            );
        }
    }
}
