# Per-provider ACP investigation

This folder is self-contained. `Invoke-Providers.ps1` uses the exact ACP launch commands currently
configured by the Intelligent Terminal prototype, asks every provider the same ordered question
list in one ACP session, and writes one JSON result per provider turn under `result/`.

```powershell
pwsh -NoProfile -File .\Test-Invoke-Providers.ps1
pwsh -NoProfile -File .\Invoke-Providers.ps1
pwsh -NoProfile -File .\Test-Results.ps1
```

Questions:

1. `The answer to life, the universe and everything?`
2. `How can the net amount of entropy of the universe be massively decreased?`

The script derives filenames from the question-array index (`claude-1.json`, `claude-2.json`, and
so on); adding a question does not require adding or renumbering filenames manually. Every real run
deletes and recreates the entire `result/` directory first, including non-JSON files such as an old
`summary.md`.

| Provider | Prototype ACP command | Captured agent version |
|---|---|---|
| Claude | `npx -y @agentclientprotocol/claude-agent-acp@0.59.0` | 0.59.0 |
| Codex | `npx -y @agentclientprotocol/codex-acp@1.1.2` | 1.1.2 |
| GitHub Copilot | `copilot --acp --stdio` | 1.0.75 |
| Gemini | `gemini --acp` | 0.51.0 |
| OpenCode | `opencode acp` | 1.18.3 |

OpenCode's current default `opencode/big-pickle` returned `No provider available`. The capture keeps
the same prototype launch command and uses standard ACP `session/set_config_option` to select the
locally advertised and health-checked `opencode/deepseek-v4-flash-free` model before asking the
shared question.

Each result contains the shared initialize/new-session response, turn number and question,
turn-scoped session updates, final prompt response, and reconstructed text answer. Results for the
same provider must carry the same ACP session ID. The script refuses to write a result containing
common credential-like fields; the result test also performs the same guard.

## Two-turn observations

The two files for each provider share one validated ACP session ID. Values below are exactly what
the two prompt responses or their turn-scoped session updates reported.

| Provider | Turn 1 | Turn 2 | Observed semantics |
|---|---|---|---|
| Claude | total 45,800; cost 0.17178825 USD | total 46,096; cost 0.1898541 USD | Prompt `totalTokens` is per-call accounting including cache categories. Standard `usage_update.cost` is session-cumulative; the second turn increases it by 0.01806585 USD. `used` is the latest context gauge. |
| Codex | total 16,411; cached read 0 | total 16,500; cached read 15,872 | Prompt Usage is per-call accounting with cache reuse, not turn-1 total plus turn-2 total. `usage_update.used` matches the latest call's reported total/context gauge. |
| GitHub Copilot | no structured Usage | no structured Usage | Accumulation semantics remain unknown. |
| Gemini | input 12,191; output 2 | input 12,209; output 41 | Private quota values change per call. Input behaves like prompt/context tokens including session history; output is turn-specific. No explicit total, session cost, or account quota is reported. |
| OpenCode | total 14,518; context used 14,464 | total 15,232; cached read 14,336; context used 14,483 | Prompt Usage is per-call accounting including cache/thought categories. `usage_update.used` is a context gauge, not `totalTokens`. Cost is zero in both turns, so this capture cannot distinguish per-turn zero from cumulative zero. |

These captures do not report account allowance, remaining balance, or reset time for any provider.
Do not add every visible field blindly: Codex thought tokens are included in output, while OpenCode
thought tokens are additive in `totalTokens`.