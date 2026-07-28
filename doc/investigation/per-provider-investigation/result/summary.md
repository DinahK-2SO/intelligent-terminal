# ACP provider usage/cost output comparison

## Scope

This comparison is based only on the captured ACP output in this directory. Each capture creates a new session and sends exactly one prompt. Therefore, a value observed here is simultaneously the value after the first request and the value of the entire one-turn session. The output cannot establish whether the same field would be per-request or session-cumulative after multiple turns; those cases are marked `UNKNOWN`.

`usage_update.used` / `usage_update.size` appears to describe context-window occupancy and capacity, not an account or plan quota. No provider in these captures returns a total account quota or remaining account quota.

## Comparison

| Provider | Input tokens | Output tokens | Explicit total tokens | Cached tokens | Thought/reasoning tokens | Context usage (`used / size`) | Monetary cost | Special pricing/quota data | Per-request or session-cumulative? |
|---|---:|---:|---:|---|---:|---|---|---|---|
| Claude | 9 | 4 | 45,944 | Read: 0; write: 45,931 | UNKNOWN | 45,944 / 1,000,000 (final update) | 0.17232825 USD | Model descriptions expose pairs such as `$5/$25 per Mtok`, but the output does not label the two rates. Account quota: `UNKNOWN` | `UNKNOWN` |
| Codex | 494 | 78 | 16,444 | Cached read/input: 15,872 | 69 | 16,444 / 258,200 | `UNKNOWN` | Per-model token breakdown is present. Monetary pricing and account quota: `UNKNOWN` | `UNKNOWN` |
| GitHub Copilot | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` | Per-model `copilotUsage` multiplier, `copilotPriceCategory`, and enablement are present. Consumed credits and account quota: `UNKNOWN` | `UNKNOWN` |
| Gemini | 12,191 | 3 | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` | `UNKNOWN` | Per-model token breakdown is present. Monetary pricing and account quota: `UNKNOWN` | `UNKNOWN` |
| OpenCode | 14,464 | 2 | 14,518 | `UNKNOWN` | 52 | 14,464 / 200,000 | 0 USD | Selected model is named `deepseek-v4-flash-free`; no rate or account quota is returned | `UNKNOWN` |

## Provider details

### Claude

Source: [claude.json](claude.json)

- `promptResponse.usage` provides `inputTokens: 9`, `outputTokens: 4`, `cachedReadTokens: 0`, `cachedWriteTokens: 45931`, and `totalTokens: 45944`.
- The total is consistent with all four token categories: $9 + 4 + 0 + 45{,}931 = 45{,}944$.
- `usage_update` is emitted three times. The final update reports `used: 45944`, `size: 1000000`, and `cost: { amount: 0.17232825000000002, currency: "USD" }`.
- Earlier updates report `used: 2, size: 935793` and then `used: 45944, size: 935793`. The response does not explain why `size` changes from 935,793 to 1,000,000, so the meaning of that transition is `UNKNOWN`.
- Model option descriptions expose pricing-looking pairs: Opus `$5/$25 per Mtok`, Sonnet `$3/$15 per Mtok`, and Haiku `$1/$5 per Mtok`. The output does not explicitly label which number is input versus output, and it does not provide cache read/write rates.
- Total account quota, remaining quota, and renewal/reset time are `UNKNOWN`.
- Whether token and cost values are for only this request or accumulated across the session is `UNKNOWN`.

### Codex

Source: [codex.json](codex.json)

- `promptResponse.usage` provides `inputTokens: 494`, `cachedReadTokens: 15872`, `outputTokens: 78`, `thoughtTokens: 69`, and `totalTokens: 16444`.
- `_meta.quota.token_count` repeats the same values with `cachedInputTokens` and `reasoningOutputTokens` names. `_meta.quota.model_usage` attributes them to `gpt-5.3-codex`.
- The total is $494 + 15{,}872 + 78 = 16{,}444$. Adding `thoughtTokens` again would overcount, so the 69 thought tokens appear to be included in the 78 output tokens in this response.
- `usage_update` reports `used: 16444` and `size: 258200` with no cost.
- Despite the `_meta.quota` name, it contains consumed token counts only. Total account quota, remaining quota, monetary cost, pricing rates, and reset time are `UNKNOWN`.
- Whether these counts are for only this request or accumulated across the session is `UNKNOWN`.

### GitHub Copilot

Source: [copilot.json](copilot.json)

- Neither `promptResponse` nor `sessionUpdates` contains token counts, context usage, or monetary cost for the request.
- Model metadata exposes a Copilot-specific pricing signal:
	- `_meta.copilotUsage`: a model-dependent multiplier such as `0x`, `0.33x`, `1x`, `3x`, `7.5x`, `14x`, or `15x`.
	- `_meta.copilotPriceCategory`: `low`, `medium`, or `high`.
	- `_meta.copilotEnablement`: `enabled` in the captured model entries.
- The selected model, `claude-sonnet-5`, reports `copilotUsage: "1x"` and `copilotPriceCategory: "medium"`.
- The response does not name the multiplier's billing unit, does not explicitly call it an AI Credit, and does not report how many credits this request consumed. AI Credit mapping, consumed credits, total/remaining account quota, and reset time are therefore `UNKNOWN`.
- Per-request versus session-cumulative semantics are `UNKNOWN` because no actual request usage value is returned.

### Gemini

Source: [gemini.json](gemini.json)

- `promptResponse._meta.quota.token_count` provides `input_tokens: 12191` and `output_tokens: 3`.
- `_meta.quota.model_usage` repeats those counts and attributes them to `gemini-3.5-flash`.
- No explicit total token field is provided. Although the two visible fields sum to 12,194, the response also emits an `agent_thought_chunk` without a thought-token count, so whether 12,194 represents all billed/used tokens is `UNKNOWN`.
- Cached tokens, thought tokens, context-window usage/capacity, monetary cost, pricing rates, total/remaining account quota, and reset time are `UNKNOWN`.
- Whether these counts are for only this request or accumulated across the session is `UNKNOWN`.

### OpenCode

Source: [opencode.json](opencode.json)

- `promptResponse.usage` provides `inputTokens: 14464`, `outputTokens: 2`, `thoughtTokens: 52`, and `totalTokens: 14518`.
- The total is consistent with thought tokens being a separate additive category: $14{,}464 + 2 + 52 = 14{,}518$.
- `usage_update` reports `used: 14464`, `size: 200000`, and `cost: { amount: 0, currency: "USD" }`. Here, `used` matches input tokens rather than `totalTokens`.
- The selected model is `opencode/deepseek-v4-flash-free`, consistent with the reported zero cost, but no monetary rate or broader pricing scheme is returned.
- Cached tokens, total/remaining account quota, and reset time are `UNKNOWN`.
- Whether token and cost values are for only this request or accumulated across the session is `UNKNOWN`.

## Normalization implications

- Do not calculate every provider's total by blindly adding every available field. Claude's cached token categories are additive; Codex's thought tokens appear included in output tokens; OpenCode's thought tokens are additive; Gemini does not expose enough fields to establish a complete total; Copilot exposes no token counts.
- `usage_update.used` is not a portable substitute for `totalTokens`: it equals total tokens for Claude and Codex in these captures, but equals input tokens for OpenCode.
- Only Claude and OpenCode return monetary `cost` objects in these captures. GitHub Copilot instead returns per-model multipliers/categories without reporting actual consumption.
- Account-level allowance, remaining balance, and reset/renewal time are `UNKNOWN` for all five providers.
