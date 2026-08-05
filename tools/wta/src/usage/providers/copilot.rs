use super::{
    PrivateUsagePolicy, ProviderUsageAdapter, ProviderUsageContribution, ProviderUsageError,
    ProviderUsageRequest,
};

pub(super) struct CopilotUsageAdapter;

pub(super) static ADAPTER: CopilotUsageAdapter = CopilotUsageAdapter;

impl ProviderUsageAdapter for CopilotUsageAdapter {
    fn family_id(&self) -> &'static str {
        crate::agent_registry::COPILOT_AGENT_ID
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

    #[test]
    fn uses_standard_acp_without_private_commands() {
        assert_eq!(
            ADAPTER.private_usage_policy(),
            PrivateUsagePolicy::StandardAcpOnly
        );
        assert!(ADAPTER.trusted_reporter_ids().is_empty());
        assert!(ADAPTER.post_turn_commands().is_empty());
    }

    #[test]
    fn ignores_private_command_outputs() {
        for command in ["/context", "/usage"] {
            let contribution = ADAPTER
                .extract_private_usage(ProviderUsageRequest {
                    reporter_id: Some("Copilot"),
                    input: ProviderUsageInput::ProviderCommandOutput {
                        command,
                        text: "provider-specific output",
                    },
                })
                .expect("disabled Copilot private usage must remain a no-op");
            assert_eq!(contribution, ProviderUsageContribution::default());
        }
    }
}
