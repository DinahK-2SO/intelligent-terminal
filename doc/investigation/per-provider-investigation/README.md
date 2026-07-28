# Per-provider ACP investigation

This folder is self-contained. `Invoke-Providers.ps1` uses the exact ACP launch commands currently
configured by the Intelligent Terminal prototype, asks every provider the same ordered question
list in one ACP session, and writes one JSON result per provider turn under `result/`.

```powershell
& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File .\Invoke-Providers.ps1
& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File .\Test-Invoke-Providers.ps1
& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File .\Test-Results.ps1
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