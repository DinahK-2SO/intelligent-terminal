# Local TDD Tools and Installation

This kit is local-only. It does not add a pipeline, scheduled task, GitHub Action,
Azure DevOps step, or release-checklist entry.

## Install

From `cmd.exe` on a fresh Windows machine:

```cmd
local-tdd-kit\install-tools.cmd
```

The command file uses `winget` to install PowerShell 7, Git and Rustup when
needed. Then `bootstrap.ps1` installs Pester and Windows App CLI when missing,
and verifies:

- Pester 5.5 or newer (`Install-Module`, current-user scope)
- Windows App CLI (`winget install Microsoft.WinAppCli`)
- PowerShell 7.2 or newer
- Git

Run a non-mutating check at any time:

```powershell
pwsh -File local-tdd-kit/bootstrap.ps1 -Check
```

Rust/Cargo and Visual Studio are required only to build product code. The command
file installs Rustup; allow Rustup to install the repository's requested toolchain.
Install the Visual Studio version and workloads required by the current
repository `.vsconfig`; the kit intentionally does not automate a system-wide
Visual Studio installation or elevation.

## Tool Ownership

| Tool | Purpose | Installation/Source |
|---|---|---|
| PowerShell 7 | Scripts, fixtures, orchestration | `install-tools.cmd` |
| Pester | Unit and live test runner | `bootstrap.ps1` |
| Windows App CLI (`winapp ui`) | Window enumeration, UIA inspect/search/invoke/value/wait, screenshots | `bootstrap.ps1` |
| `wtcli.exe` | Package-scoped tabs, panes, input, capture and event stream | Co-located in deployed package |
| `wta.exe` | Agent helper/master and test target | Built by Cargo, co-located in package |
| Win32 `user32.dll` | Verified foreground window, client-coordinate mouse and OS keyboard input | Windows built-in; no install |
| Cargo/Rust | Build/test WTA | `rustup` |
| MSBuild/DeployAppRecipe | Build and register CascadiaPackage | Visual Studio + Windows SDK |
| Git | Source identity and build receipt fingerprint | `install-tools.cmd` |

Optional policy tests use `tools/Enable-WtAgentPolicyTesting.ps1`. It displays a
UAC prompt and grants the current user write access only to the Intelligent
Terminal policy test key. Restore with `tools/Disable-WtAgentPolicyTesting.ps1`.
Do not run either script unless the issue actually exercises GPO behavior.

## Capabilities

All window-level input validates that `App.Hwnd` is still owned by `App.Pid`.
This prevents a recycled HWND or unrelated foreground application from receiving
test input.

```powershell
$app = Start-Terminal -Package Dev

# Exact launched-window identity and client bounds.
$identity = Get-WtWindowIdentity -App $app

# Client-area coordinates: left/right, single/double click.
Invoke-WtWindowMouse -App $app -X 120 -Y 90 -Button Left -ClickCount 1
Invoke-WtWindowMouse -App $app -X 120 -Y 90 -Button Right -ClickCount 2

# Named OS keys and chords sent to the target window.
Send-WtWindowKeyChord -App $app -Chord @('Up', 'Enter', 'Ctrl+Shift+P')

# UI Automation selectors when a stable AutomationId exists.
Invoke-UiElement -App $app -Selector AgentToggleButton
Invoke-UiClick -App $app -Selector NewTabButton -Double
Set-UiValue -App $app -Selector '<AutomationId>' -Value '<text>'

# Agent TUI text and input through its own ConPTY session.
$session = Send-AgentPrompt -App $app -Text 'draft' -NoSubmit
Send-AgentKey -App $app -PaneSessionId $session.PaneSessionId -Key Enter
Send-AgentKey -App $app -Key Down -Count 2
Send-AgentWin32Key -App $app -Vk 0x56 -Sc 0x2F -Modifiers 0x02 # Alt+V

# Observe and preserve evidence locally.
$listener = Start-WtEventListener -App $app
Save-UiScreenshot -App $app -Path local-tdd-kit/artifacts/window.png
Get-WtCapture -App $app -SessionId (Get-ActivePane -App $app).session_id
Stop-Terminal -App $app
```

## Input Safety

- Coordinate mouse and OS keyboard tests require an unlocked interactive desktop.
- Do not run foreground-input suites in parallel.
- Coordinates are relative to the window client area, not the screen.
- `Invoke-WtWindowMouse` bounds-checks, foregrounds, revalidates ownership, sends
  input, and restores the user's cursor by default.
- Prefer UIA selector invocation over coordinates when a stable AutomationId exists.
- `Start-Terminal` backs up settings/state; `Stop-Terminal` restores them.
- Artifacts, provider configs, logs, captures and screenshots remain ignored.
- `Invoke-BuildDeploy.ps1 -Launch` may activate the Dev Terminal and move foreground focus away
  from VS Code. Prefer a non-launching build and let the E2E harness launch immediately before
  input. A focus flash is expected window activation, not evidence that VS Code was terminated.

## Optional AI Oracle

`Assert-AI` and `Invoke-AgentJudge` call an external authenticated agent CLI and
may send the supplied context to that provider. They are disabled by default.
Review and sanitize the context, then explicitly set
`ITE2E_ENABLE_AI_ORACLE=1` for a test that genuinely requires model judgment.
The deterministic `AgentInput` self-test does not use this oracle or any network.