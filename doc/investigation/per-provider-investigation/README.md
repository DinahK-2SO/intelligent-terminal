# Per-provider ACP investigation

This folder is self-contained. `Invoke-Providers.ps1` uses the exact ACP launch commands currently
configured by the Intelligent Terminal prototype, asks every provider the same question, and writes
one JSON result per provider under `result/`.

```powershell
& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File .\Invoke-Providers.ps1
& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File .\Test-Invoke-Providers.ps1
& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File .\Test-Results.ps1
```

Question: `The answer to life, the universe and everything?`

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

Each result contains the initialize response, new-session response, session updates, final prompt
response, and reconstructed text answer. The script refuses to write a result containing common
credential-like fields; the result test also performs the same guard.