mod claude;
mod codex;
mod copilot;
mod gemini;
mod opencode;

use super::UsageCost;

#[derive(Debug, Clone)]
pub struct ProviderLocalUsageCursor {
    path: std::path::PathBuf,
    offset: u64,
    family_id: &'static str,
    schema_id: &'static str,
}

impl ProviderLocalUsageCursor {
    pub(super) fn jsonl(
        path: std::path::PathBuf,
        family_id: &'static str,
        schema_id: &'static str,
    ) -> Self {
        let offset = std::fs::metadata(&path).map_or(0, |metadata| metadata.len());
        Self {
            path,
            offset,
            family_id,
            schema_id,
        }
    }

    fn error(&self, class: &'static str) -> ProviderUsageError {
        ProviderUsageError {
            family_id: self.family_id,
            schema_id: self.schema_id,
            class,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PrivateUsagePolicy {
    /// Standard ACP UsageUpdate is the only enabled source for this family.
    StandardAcpOnly,
    /// A provider-specific adapter slot exists, but no private schema is trusted yet.
    Reserved,
    /// Versioned, allowlisted local agent sources have been verified end to end.
    VerifiedLocalSources,
    /// Provider-specific usage is intentionally excluded from the current product scope.
    OutOfScope,
}

#[derive(Debug, Clone, Copy)]
pub enum ProviderUsageInput<'a> {
    SessionUpdateMeta(&'a serde_json::Value),
    PromptResponseMeta(&'a serde_json::Value),
    ExtensionNotification {
        method: &'a str,
        params: &'a serde_json::Value,
    },
    /// A response already obtained by a separately reviewed auth/network source.
    /// Provider adapters parse it; they never read CLI credentials or perform HTTP here.
    ProviderApiResponse {
        schema_id: &'a str,
        body: &'a serde_json::Value,
    },
    /// Human-readable output from an allowlisted local agent command executed
    /// on the existing ACP session. Provider adapters own its versioned schema.
    ProviderCommandOutput {
        command: &'a str,
        text: &'a str,
    },
    /// One parsed event from the agent's own session event stream.
    ProviderSessionEvent(&'a serde_json::Value),
}

#[derive(Debug, Clone, Copy)]
pub struct ProviderUsageRequest<'a> {
    pub reporter_id: Option<&'a str>,
    pub input: ProviderUsageInput<'a>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderContextUsage {
    pub used: u64,
    pub size: u64,
    pub used_display_text: String,
    pub size_display_text: String,
    pub reported_percent: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderUsageMetric {
    pub metric_id: String,
    pub value_decimal_text: String,
    pub limit_decimal_text: Option<String>,
    pub unit_id: String,
}

/// Partial provider contribution merged only after the standard ACP normalizer.
/// Optional fields allow a verified extension to report cost without inventing tokens.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ProviderUsageContribution {
    pub context: Option<ProviderContextUsage>,
    pub cost: Option<UsageCost>,
    pub metrics: Vec<ProviderUsageMetric>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderUsageError {
    pub family_id: &'static str,
    pub schema_id: &'static str,
    pub class: &'static str,
}

impl std::fmt::Display for ProviderUsageError {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            formatter,
            "provider usage rejected: family={} schema={} class={}",
            self.family_id, self.schema_id, self.class
        )
    }
}

impl std::error::Error for ProviderUsageError {}

/// Provider-private usage parser. The caller always applies the standard ACP normalizer first,
/// then selects one of these adapters by effective family and verified reporter identity.
pub trait ProviderUsageAdapter: Sync {
    fn family_id(&self) -> &'static str;
    fn private_usage_policy(&self) -> PrivateUsagePolicy;
    fn trusted_reporter_ids(&self) -> &'static [&'static str];
    fn begin_local_usage(&self, _session_id: &str) -> Option<ProviderLocalUsageCursor> {
        None
    }
    fn post_turn_commands(&self) -> &'static [&'static str] {
        &[]
    }
    fn extract_private_usage(
        &self,
        request: ProviderUsageRequest<'_>,
    ) -> Result<ProviderUsageContribution, ProviderUsageError>;
}

async fn read_local_usage(
    adapter: &'static dyn ProviderUsageAdapter,
    reporter_id: Option<&str>,
    cursor: &ProviderLocalUsageCursor,
) -> Result<Option<ProviderUsageContribution>, ProviderUsageError> {
    use tokio::io::{AsyncBufReadExt, AsyncSeekExt};

    let mut file = match tokio::fs::File::open(&cursor.path).await {
        Ok(file) => file,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(_) => return Err(cursor.error("local_source_open_failed")),
    };
    let length = file
        .metadata()
        .await
        .map_err(|_| cursor.error("local_source_metadata_failed"))?
        .len();
    file.seek(std::io::SeekFrom::Start(cursor.offset.min(length)))
        .await
        .map_err(|_| cursor.error("local_source_seek_failed"))?;
    let mut lines = tokio::io::BufReader::new(file).lines();
    let mut latest = None;
    loop {
        let line = lines
            .next_line()
            .await
            .map_err(|_| cursor.error("local_source_read_failed"))?;
        let Some(line) = line else {
            break;
        };
        let event: serde_json::Value = match serde_json::from_str(&line) {
            Ok(event) => event,
            Err(_) => continue,
        };
        let contribution = adapter.extract_private_usage(ProviderUsageRequest {
            reporter_id,
            input: ProviderUsageInput::ProviderSessionEvent(&event),
        })?;
        if contribution != ProviderUsageContribution::default() {
            latest = Some(contribution);
        }
    }
    Ok(latest)
}

pub async fn wait_for_local_usage(
    adapter: &'static dyn ProviderUsageAdapter,
    reporter_id: Option<&str>,
    cursor: ProviderLocalUsageCursor,
) -> Result<Option<ProviderUsageContribution>, ProviderUsageError> {
    let deadline = tokio::time::Instant::now() + std::time::Duration::from_secs(3);
    loop {
        if let Some(contribution) = read_local_usage(adapter, reporter_id, &cursor).await? {
            return Ok(Some(contribution));
        }
        if tokio::time::Instant::now() >= deadline {
            return Ok(None);
        }
        tokio::time::sleep(std::time::Duration::from_millis(50)).await;
    }
}

static PROVIDERS: [&dyn ProviderUsageAdapter; 5] = [
    &copilot::ADAPTER,
    &claude::ADAPTER,
    &codex::ADAPTER,
    &gemini::ADAPTER,
    &opencode::ADAPTER,
];

pub fn all() -> &'static [&'static dyn ProviderUsageAdapter] {
    &PROVIDERS
}

pub fn lookup(family_id: &str) -> Option<&'static dyn ProviderUsageAdapter> {
    PROVIDERS
        .iter()
        .copied()
        .find(|provider| provider.family_id() == family_id)
}

pub(super) fn no_verified_private_usage(
    request: ProviderUsageRequest<'_>,
) -> Result<ProviderUsageContribution, ProviderUsageError> {
    let _ = request.reporter_id;
    match request.input {
        ProviderUsageInput::SessionUpdateMeta(meta)
        | ProviderUsageInput::PromptResponseMeta(meta) => {
            let _ = meta;
        }
        ProviderUsageInput::ExtensionNotification { method, params } => {
            let _ = (method, params);
        }
        ProviderUsageInput::ProviderApiResponse { schema_id, body } => {
            let _ = (schema_id, body);
        }
        ProviderUsageInput::ProviderCommandOutput { command, text } => {
            let _ = (command, text);
        }
        ProviderUsageInput::ProviderSessionEvent(event) => {
            let _ = event;
        }
    }
    Ok(ProviderUsageContribution::default())
}
