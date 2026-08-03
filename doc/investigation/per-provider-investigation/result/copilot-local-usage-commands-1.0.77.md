# GitHub Copilot CLI 1.0.77 local usage commands

> **Correction (2026-08-03, Step 50):** this experiment proved that `/usage` and `/context`
> commands do not consume model usage, but its original conclusion incorrectly treated
> `/usage`'s `Requests: N AI Units` as actual AI credits. Real session checkpoints prove that N is
> a request/premium count. Authoritative session AI credits are
> `session.usage_checkpoint.data.totalNanoAiu / 1_000_000_000`.
>
> Real counterexample: an authenticated ACP session reported `Requests: 0 AI Units` while its
> same-session checkpoint was `4,416,205,500 nano-AIU = 4.4162055 AIC`. A real Bonjour session
> had one premium request and `7,553,900,000 nano-AIU = 7.5539 AIC`.

Captured: 2026-08-03 using `copilot --acp --stdio`, protocol version 1.

## Question

Do `/usage` and `/context` consume model tokens or AI Units when sent through ACP on an existing session?

## Method

Experiment A used one ACP session and saved every turn as an individual JSON file:

1. Normal prompt (`Q1_OK`).
2. `/usage`.
3. Normal prompt (`Q2_OK`).
4. `/usage`.
5. Fifteen additional `/usage` prompts.

Experiment B used a separate ACP session:

1. One normal prompt.
2. `/usage` baseline.
3. Five alternating `/context` and `/usage` pairs.

The 19 Experiment A responses and 12 Experiment B responses remain locally under the ignored paths:

- `test/e2e/artifacts/copilot-usage-command/`
- `test/e2e/artifacts/copilot-context-command/`

`test/e2e/artifacts/copilot-usage-command/evidence-manifest.json` records a SHA256 for every raw turn file. Both evidence sets use one SessionId each and passed a credential-pattern guard.

## Results

### `/usage`

| Point | Requests | Input | Output | Cached |
|---|---:|---:|---:|---:|
| After question 1 | 1 AI Units | 39.8k | 8 | 0 |
| After question 2 | 2 AI Units | 79.7k | 16 | 39.8k |
| Repeated `/usage` 1 through 15 | 2 AI Units | 79.7k | 16 | 39.8k |

All fifteen repeated `/usage` responses had one identical value tuple:

```text
2 AI Units | input 79.7k | output 16 | cached 39.8k
```

Only the elapsed-session seconds in parentheses changed. No standard ACP `usage_update` was emitted; the command returned one human-readable `agent_message_chunk` and `stopReason: end_turn`.

### `/context`

The command reported a context summary whose first line contained:

```text
claude-sonnet-5 · 30k/264k tokens (11%)
```

Across five `/context` calls, the context values were unchanged. The `/usage` baseline and all five post-`/context` checks also remained identical:

```text
1 AI Units | input 39.8k | output 11 | cached 17.3k
```

`/context` likewise returned human-readable `agent_message_chunk` text and did not emit standard ACP Usage.

## Conclusion

For GitHub Copilot CLI 1.0.77 in these authenticated ACP sessions, `/usage` and `/context` did not consume model usage. Only `/context` remains an automatic post-turn command; `/usage` is no longer sent because its Requests field is not AIC.

The two commands expose different data and must not be conflated:

- `/context` is the source for context occupancy/capacity and percentage.
- `/usage` is not a valid source for session AIC; its Requests field is ignored.
- `session.usage_checkpoint.data.totalNanoAiu` is the verified source for session AIC.
- `/usage` input/output/cached totals are not context-window occupancy and are not displayed.
- Intelligent Terminal displays exact `totalNanoAiu / 1e9` with unit `AIC`, matching the CLI's
	native `ai-used` accounting rather than the ACP `/usage` Requests label.

These outputs are a versioned human-readable CLI schema, not an ACP standard. Parsing must be allowlisted to the built-in Copilot family and exact reporter identity, fail closed on format drift, avoid logging values, and automatically defer to standard ACP Usage when Copilot adds it.
