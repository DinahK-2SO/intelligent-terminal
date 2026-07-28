# ACP provider usage/cost output comparison

## Scope

This comparison uses two consecutive prompts sent to the same ACP session for each provider. The matching `sessionId` values in each `*-1.json` / `*-2.json` pair confirm that the second capture continues the first session.

Notation used below:

- `I`: input tokens
- `O`: output tokens
- `CR`: cached-read/input tokens
- `CW`: cached-write tokens
- `R`: thought/reasoning tokens
- `T`: provider-reported total tokens

“Current request” means the current model call. Its input can include the earlier conversation, often as cached tokens, so it is not merely the newly typed user text. “Session cumulative” means that the second value includes usage/cost from both prompts.

## Comparison

| Provider | Context-window data (turn 1 → turn 2) | Context scope established by two turns | Monetary cost (turn 1 → turn 2) | Cost scope established by two turns | Token data (turn 1 → turn 2) | Token scope established by two turns | Special pricing/quota data | Special pricing/quota scope established by two turns |
|---|---|---|---|---|---|---|---|---|
| Claude | `45,800 / 1,000,000` → `46,096 / 1,000,000` | **Current gauge**. Turn 2 reports 46,096 tokens currently in context, an increase of 296 from turn 1. Use 46,096 as the latest snapshot; do not add it to 45,800. | `0.17178825 USD` → `0.18985410 USD` | **Session cumulative**. The second turn increases the session cost by `0.01806585 USD`; do not add the two snapshots. | T1: `I 9`, `O 4`, `CR 0`, `CW 45,787`, `T 45,800`<br>T2: `I 2`, `O 282`, `CR 45,787`, `CW 25`, `T 46,096` | **Current model call**, not session cumulative. Prior cache-write tokens appear as cache reads in turn 2. | Model descriptions expose input/output price pairs; prompt usage separates cache reads/writes. Account quota: `UNKNOWN` | Model prices are static model metadata, not turn usage. Account quota scope: `UNKNOWN` because no allowance is reported in either turn. |
| Codex | `16,411 / 258,200` → `16,500 / 258,200` | **Current gauge**. Turn 2 reports 16,500 tokens currently in context, an increase of 89 from turn 1. Use 16,500 as the latest snapshot; do not add it to 16,411. | T1: `UNKNOWN`<br>T2: `UNKNOWN` | `UNKNOWN`; neither turn reports monetary cost. | T1: `I 16,366`, `O 45`, `CR 0`, `R 36`, `T 16,411`<br>T2: `I 521`, `O 107`, `CR 15,872`, `R 40`, `T 16,500` | **Current model call**, not session cumulative. Turn 2 includes prior context as cached input. `R` is included in `O`, not additive. | `_meta.quota` provides per-model token breakdown. Account allowance: `UNKNOWN` | Token breakdown is **current model call** data despite the `quota` name. Account quota scope: `UNKNOWN`; no allowance is reported. |
| GitHub Copilot | T1: `UNKNOWN`<br>T2: `UNKNOWN` | `UNKNOWN`; neither turn sends `usage_update`. | T1: `UNKNOWN`<br>T2: `UNKNOWN` | `UNKNOWN`; neither turn reports monetary cost. | T1: `UNKNOWN`<br>T2: `UNKNOWN` | `UNKNOWN`; neither turn reports token usage. | Static per-model `copilotUsage` multiplier, `copilotPriceCategory`, and enablement. Actual AI Units/credits and account quota: `UNKNOWN` | Model metadata is static configuration, not actual per-turn or session consumption. Consumption and account-quota scope: `UNKNOWN`. |
| Gemini | T1: `UNKNOWN`<br>T2: `UNKNOWN` | `UNKNOWN`; neither turn sends standard `usage_update`. | T1: `UNKNOWN`<br>T2: `UNKNOWN` | `UNKNOWN`; neither turn reports monetary cost. | T1: `I 12,191`, `O 2`, explicit `T UNKNOWN`<br>T2: `I 12,209`, `O 41`, explicit `T UNKNOWN` | **Current model call**, not session cumulative. Input includes conversation context; cache/thought breakdown and a complete total are `UNKNOWN`. | `_meta.quota.model_usage` attributes each turn’s token counts to `gemini-3.5-flash`. Account allowance: `UNKNOWN` | Per-model token data is **current model call** data. Account quota scope: `UNKNOWN`; no allowance is reported. |
| OpenCode | `14,464 / 200,000` → `14,483 / 200,000` | **Current gauge**. Turn 2 reports 14,483 tokens currently in context, an increase of 19 from turn 1. Use 14,483 as the latest snapshot; do not add it to 14,464. `used` is input plus cached-read context, not per-call total. | `0 USD` → `0 USD` | `UNKNOWN`. Both turns are zero, so the responses cannot distinguish per-call zero from a cumulative zero snapshot. | T1: `I 14,464`, `O 2`, `R 52`, `T 14,518`<br>T2: `I 147`, `O 39`, `CR 14,336`, `R 710`, `T 15,232` | **Current model call**, not session cumulative. Turn 2 moves prior context into cache reads; `R` is additive in `T`. | Selected model is `opencode/deepseek-v4-flash-free`; monetary rates and account allowance: `UNKNOWN` | Model selection is session configuration. Pricing and account-quota scope: `UNKNOWN`; no rates or allowance are reported. |

No provider reports a total account/plan quota, remaining account quota, or quota reset time in these captures. Those values are `UNKNOWN` for all five providers. Fields named `_meta.quota` in Codex and Gemini contain token counts, not an account allowance.

## Context-window scope

Standard ACP defines `UsageUpdate.used` as **tokens currently in context** and `UsageUpdate.size` as the **total context-window size**. This is a current session/model context gauge, not per-request token consumption and not lifetime session consumption.

The client can display the latest valid `used / size` notification directly:

| Provider | Standard context gauge reported? | Latest value after turn 2 | Occupancy | Remaining context |
|---|---|---:|---:|---:|
| Claude | Yes | `46,096 / 1,000,000` | 4.61% | 953,904 |
| Codex | Yes | `16,500 / 258,200` | 6.39% | 241,700 |
| GitHub Copilot | No | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` |
| Gemini | No | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` |
| OpenCode | Yes | `14,483 / 200,000` | 7.24% | 185,517 |

Display rules:

- Treat the notification as a latest-value gauge: replace the previous `used`, `size`, and optional cumulative `cost`; do not add context values across turns.
- Use $used / size$ for the occupancy percentage and $size - used$ for remaining context. A stable end-of-turn display should use the final update received for that turn.
- `used` can include system instructions, tool definitions, retained conversation history, and other provider-managed prompt context. It need not equal the visible chat text.
- The gauge may decrease after compaction or truncation. `size` may also change after a model/configuration change; Claude even emitted an intermediate size of 935,793 before its final 1,000,000 value. Always replace both fields.
- Equality between `used` and `PromptResponse.usage.totalTokens` for Claude/Codex in these samples is an adapter-specific observation, not a portable formula. OpenCode demonstrates the distinction: its turn-2 `used` is input-side context $147 + 14{,}336 = 14{,}483$, while per-call `totalTokens` is 15,232 after output and thought tokens.

If the UI instead wants **total tokens processed during the session**, that is a separate cumulative consumption metric and must be derived from per-call usage (without double-counting nested fields such as Codex reasoning tokens). Summing the two reported per-call totals gives 91,896 for Claude, 32,911 for Codex, and 29,750 for OpenCode. Gemini does not expose a guaranteed-complete total, and Copilot exposes no token usage, so their cumulative totals are `UNKNOWN`. These sums must not be used as context-window occupancy.

## Provider details

### Claude

Sources: [claude-1.json](claude-1.json), [claude-2.json](claude-2.json)

- First response: `inputTokens: 9`, `outputTokens: 4`, `cachedReadTokens: 0`, `cachedWriteTokens: 45787`, `totalTokens: 45800`.
- Second response: `inputTokens: 2`, `outputTokens: 282`, `cachedReadTokens: 45787`, `cachedWriteTokens: 25`, `totalTokens: 46096`.
- Each total is the sum of that response’s token categories:
	- First: $9 + 4 + 0 + 45{,}787 = 45{,}800$.
	- Second: $2 + 282 + 45{,}787 + 25 = 46{,}096$.
- The second response reclassifies the prior cache write as a cache read. Therefore, `promptResponse.usage` is current-request usage including cached session history, not a running sum of tokens consumed by both requests. A cumulative billed-token sum across the two responses would be 91,896, which is not emitted as a field.
- Final `usage_update.used` equals the current response’s `totalTokens`. It is not a two-response accumulated total.
- `usage_update.cost` **is session cumulative**. It rises from `0.17178825 USD` to `0.18985410 USD`; the second request therefore adds `0.01806585 USD`.
- The observed costs exactly match effective rates of `$3/M` input, `$15/M` output, `$0.30/M` cache read, and `$3.75/M` cache write. Only the `$3/$15 per Mtok` input/output pair is visible in the model descriptions; the cache rates are inferred from the exact cost arithmetic.
- The first capture temporarily emits `size: 935793` before ending at `size: 1000000`. The reason for that transition is `UNKNOWN`.
- Total account quota, remaining quota, and reset time: `UNKNOWN`.

### Codex

Sources: [codex-1.json](codex-1.json), [codex-2.json](codex-2.json)

- First response: `inputTokens: 16366`, `cachedReadTokens: 0`, `outputTokens: 45`, `thoughtTokens: 36`, `totalTokens: 16411`.
- Second response: `inputTokens: 521`, `cachedReadTokens: 15872`, `outputTokens: 107`, `thoughtTokens: 40`, `totalTokens: 16500`.
- `_meta.quota.token_count` repeats the same data using the names `cachedInputTokens` and `reasoningOutputTokens`. `_meta.quota.model_usage` attributes all counts to `gpt-5.3-codex`.
- In both responses, `totalTokens = inputTokens + cachedReadTokens + outputTokens`. `thoughtTokens` is a subset of `outputTokens` and must not be added again.
- The second total is not the first total plus the second request. It describes the current model call, whose input contains 15,872 cached tokens from existing session context.
- `usage_update.used` equals the current response’s `totalTokens`; `size` remains 258,200. These are context-window data, not account quota.
- Monetary cost, pricing rates, total/remaining account quota, and reset time: `UNKNOWN`.

### GitHub Copilot

Sources: [copilot-1.json](copilot-1.json), [copilot-2.json](copilot-2.json)

- Neither response contains `promptResponse.usage`, a `usage_update`, token counts, context-window usage, monetary cost, or actual credit consumption.
- Model metadata exposes a Copilot-specific pricing signal:
	- `_meta.copilotUsage`: a model-dependent multiplier such as `0x`, `0.33x`, `1x`, `3x`, `7.5x`, `14x`, or `15x`.
	- `_meta.copilotPriceCategory`: `low`, `medium`, or `high`.
	- `_meta.copilotEnablement`: whether the model is enabled.
- The selected `claude-sonnet-5` model reports `copilotUsage: "1x"` and `copilotPriceCategory: "medium"`.
- The response does not name the multiplier’s billing unit or explicitly call it an AI Credit. Whether one request consumes that multiplier in AI Credits, how many credits these requests consumed, the account allowance, remaining credits, and reset time are all `UNKNOWN`.
- Per-request versus session-cumulative semantics: `UNKNOWN`, because neither response returns an actual usage value.

### Gemini

Sources: [gemini-1.json](gemini-1.json), [gemini-2.json](gemini-2.json)

- First response `_meta.quota.token_count`: `input_tokens: 12191`, `output_tokens: 2`.
- Second response: `input_tokens: 12209`, `output_tokens: 41`.
- `_meta.quota.model_usage` repeats each response’s counts and attributes them to `gemini-3.5-flash`.
- The second response does not add the first response’s counts. Instead, its input count is slightly larger because the current model request includes prior conversation context. These are current-request/model-call values, not session-cumulative consumption.
- There is no explicit total token field. The visible input/output sums are 12,193 and 12,250, but whether they represent all billed/used tokens is `UNKNOWN` because thought and cache token counts are not supplied.
- Cached tokens, thought tokens, context-window usage/capacity, monetary cost, pricing rates, total/remaining account quota, and reset time: `UNKNOWN`.

### OpenCode

Sources: [opencode-1.json](opencode-1.json), [opencode-2.json](opencode-2.json)

- First response: `inputTokens: 14464`, `outputTokens: 2`, `thoughtTokens: 52`, `totalTokens: 14518`.
- Second response: `inputTokens: 147`, `cachedReadTokens: 14336`, `outputTokens: 39`, `thoughtTokens: 710`, `totalTokens: 15232`.
- Each total is the sum of that response’s categories:
	- First: $14{,}464 + 2 + 52 = 14{,}518$.
	- Second: $147 + 14{,}336 + 39 + 710 = 15{,}232$.
- The second response moves most prior context into `cachedReadTokens`, proving that `promptResponse.usage` describes the current request rather than a running sum of both responses.
- `usage_update.used` has different semantics from Claude and Codex. It is input-side context usage: first `14464`, then $147 + 14{,}336 = 14{,}483$. It excludes output and thought tokens. `size` remains 200,000.
- Both updates report `cost: { amount: 0, currency: "USD" }`. The selected model is `opencode/deepseek-v4-flash-free`, so zero cost is consistent with the model name. Because adding zero to zero is still zero, the two responses cannot reveal whether OpenCode’s cost field is per-request or session cumulative; that scope is `UNKNOWN`.
- Monetary rates, cached-token pricing, total/remaining account quota, and reset time: `UNKNOWN`.

## Normalization implications

- Treat `promptResponse.usage` / `_meta.quota.token_count` as current-model-call data for Claude, Codex, Gemini, and OpenCode. Do not sum successive “total” fields as though each were a session snapshot.
- Current-request input can include earlier conversation context. Cached history is explicit for Claude, Codex, and OpenCode; Gemini only exposes a combined input count.
- Do not normalize totals by blindly adding every field. Codex reasoning tokens are included in output tokens, while OpenCode thought tokens are additive. Claude cache read/write tokens are additive. Gemini exposes no explicit total. Copilot exposes no token counts.
- `usage_update.used` is provider-dependent: it equals current total tokens for Claude and Codex, but input plus cached-read tokens for OpenCode.
- Standard `usage_update.used / size` can be displayed directly as the latest context-window gauge. It is neither account/plan quota nor cumulative session token consumption.
- Only Claude proves a session-cumulative monetary cost in this two-turn sample. OpenCode returns zero for both responses, so its cost accumulation semantics remain `UNKNOWN`. Codex, Copilot, and Gemini return no monetary cost.
