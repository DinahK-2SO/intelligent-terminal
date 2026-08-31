# Intelligent Terminal

Intelligent Terminal is a Windows Terminal fork that adds first-class AI agent
workflows. The inherited Windows Terminal build, architecture, and C++ conventions
are documented in `.github/copilot-instructions.md`; this file contains only the
fork-specific context.

## Clean-room streaming Markdown work

This branch is the coordination and handoff branch for a clean-room implementation
of a reusable streaming Markdown package and its later Intelligent Terminal
integration. It intentionally contains requirements and process material, not the
previous proof-of-concept implementation.

The controlling requirements are:

- `doc/specs/streaming-markdown-package-clean-room.md` for the external package;
- `doc/specs/agent-markdown-rendering-clean-room.md` for the host integration.

### Language and deliverables

- Clean-room requirements, coordination records, and internal review documents may
  be written in Chinese because the implementation team can review Chinese.
- Public package code, identifiers, comments, API documentation, examples, issues,
  RFCs, pull requests, commit messages, changelogs, release notes, security policy,
  and Intelligent Terminal product documentation must be written in English.
- Requirements must describe observable behavior and complexity constraints. They
  must not prescribe names for internal state, types, functions, or tests.

### Access boundary

- Package implementers must not have read the previous Intelligent Terminal proof
  of concept or any restricted third-party streaming Markdown implementation.
- Use only the approved clean `tui-markdown` baseline, the two requirements documents
  above, public Markdown standards, and resources on the approved allowlist.
- Do not fetch, check out, search, diff, inspect, or ask an AI tool to summarize old
  feature branches, pull requests, commits, reflogs, unreachable Git objects,
  investigation notes, prior tests, transcripts, logs, screenshots, or build output.
- Use a fresh clone, fresh editor/search index, and fresh AI session without memory
  or retrieval from a workspace that contained restricted material.
- If restricted material is exposed, stop immediately, quarantine all subsequent
  work, record the incident, and wait for the coordinator and legal reviewer to
  decide whether work or personnel must be replaced.

This repository branch is not the package implementation environment. Implement the
package in a separately provisioned clean repository created from the approved
official baseline. The integration team may use this main-based branch after the
package API is frozen, but must not recreate package parsing or rendering logic here.

### Ownership boundary

The external package owns:

- ordered visible UTF-8 Markdown source and document lifecycle operations;
- incremental parsing and rendering, stable-progress reporting, affected-region
  traceback, canonical batch parity, and bounded derived state;
- tables, unfinished syntax, definitions with document-wide effects, code blocks,
  Unicode, line endings, context reflow, and safe fallback behavior described by the
  package specification;
- a consumer-owned state object and deterministic Ratatui styled output.

Intelligent Terminal owns:

- provider and transcript event ordering, raw message persistence, and completion;
- reveal cadence and network-burst coalescing;
- settings and runtime propagation;
- pane-relative style input, response markers, viewport, scrolling, selection,
  mouse geometry, and completed-history retention;
- process and conversation identity.

Do not duplicate package behavior in the host. Disabled Markdown mode must bypass the
package rather than configure a second parser or renderer.

### Development workflow

1. The coordinator approves the implementation-facing specification, participant
   attestations, source/dependency/tool allowlist, clean source manifest, and resource
   budget before product implementation begins.
2. The clean-room team writes independent tests from the approved requirements. Do
   not reuse, translate, inspect, or mechanically transform prior implementation
   tests or fixtures.
3. For every behavior, establish a focused RED, implement the smallest GREEN, rerun
   the same check immediately, then run differential, property, fuzz, full-crate,
   documentation, and static-analysis checks appropriate to the change.
4. At every submitted source prefix, incremental output must equal a fresh batch
   render under the same options and context. Performance evidence must also prove
   that confirmed source is not repeatedly parsed or rendered during ordinary append.
5. Maintain one clean implementation history. Upstream discussion, implementation,
   independent validation, public fallback release automation, and a host adapter
   prototype may proceed concurrently, but must not create competing algorithms.
6. Prefer upstream contribution. If upstream declines the scope, publish the same
   implementation as an openly licensed companion package where possible, otherwise
   as a clearly named and attributed public fork approved by legal review.
7. Do not publish or integrate until provenance, source-similarity, license,
   dependency, security, resource-bound, and reproducible-build reviews pass.

### Git and evidence discipline

- Do not fetch or add remotes containing restricted implementation history.
- Do not rewrite history or use destructive Git commands without coordinator
  approval. Never remove evidence to conceal an exposure or failed validation.
- Keep package product commits, host integration commits, and restricted coordination
  evidence separate. Never copy local credentials, machine paths, private logs, or
  ignored artifacts into a public commit.
- Record exact source commits, dependency archives, toolchain versions, artifact
  hashes, test results, and release checksums in the approved evidence store.
- This branch does not authorize a push or public release by itself. Follow the
  coordinator-approved remote, review, and publication plan.

## Architecture

```
WindowsTerminal.exe
  |-- TerminalProtocolComServer (COM, discovered through WT_COM_CLSID)
  |-- SharedWta --> wta-master --> agent CLI pool (ACP over stdio)
  +-- one wta-helper pane per tab
                       |
                       +-- helper/master ACP over a named pipe
                       +-- session-scoped MCP tools

Agent or human CLI --> wta/wtcli --> COM IProtocolServer --> Windows Terminal
```

- **WTA** (`tools/wta/`) is the Rust orchestrator.
- **ACP** means Agent Client Protocol. `wta-master` lazily owns a pool of agent
  CLI processes keyed by agent identity, execution source, and command; helpers
  using the same key share one process and multiplex sessions through it.
- **WT Protocol** is the terminal-control boundary. `wtcli.exe` activates
  `IProtocolServer` through the package COM registration.
- **Session MCP** exposes `request_terminal_actions` and `request_user_input`.
  It routes requests to the owning helper and never executes terminal actions
  itself.
- Agent panes are ordinary `ConptyConnection` panes hosting `wta-helper`; C++
  does not speak ACP.

See `doc/specs/Multi-window-agent-pane.md` for the detailed lifecycle and
`tools/wta/AGENTS.md` for WTA-specific implementation rules.

## Supported agents and settings

Built-in ACP and delegation providers are Copilot, Claude, Codex, Gemini, and
OpenCode. Custom providers use a `custom:<name>` ID plus the matching custom
command setting.

```jsonc
{
    "acpAgent": "copilot",
    "acpModel": "",
    "acpCustomCommand": "",
    "delegateAgent": "copilot",
    "delegateModel": "",
    "delegateCustomCommand": "",
    "agentPanePosition": "bottom",
    "autoErrorDetectionEnabled": true,
    "autoFixEnabled": false,
    "aiIntegration.coordinator.enabled": false,
    "aiIntegration.coordinator.commandline": "wta",
    "aiIntegration.coordinator.profile": "{fd19208a-412b-4857-8a2d-9ca592b4b16e}",
    "aiIntegration.confirmation.readOperations": "auto",
    "aiIntegration.confirmation.createOperations": "auto",
    "aiIntegration.confirmation.inputOperations": "auto"
}
```

The settings model is authoritative; check
`src/cascadia/TerminalSettingsModel/MTSMSettings.h` and
`src/cascadia/inc/AgentRegistry.h` before documenting defaults or providers.

## User-facing behavior

| Trigger | Behavior |
| --- | --- |
| `>Toggle AI assistant` | Stash or restore the current tab's agent pane |
| `?<prompt>` | Delegate a prompt through WTA |
| `?` | No-op |
| `&<prompt>` | Reserved background-task entry point; currently a no-op |

Important invariants:

- Each eligible tab pre-warms one stashed helper. Skip pre-warm when WTA is
  unavailable, policy blocks all agents, the tab has no active terminal, or a
  dragged-in agent pane already exists.
- Toggling an agent pane stashes/restores it; it does not destroy the helper,
  ACP session, or chat history.
- Per-tab events carry tab and window identity. Route responses to the owning
  tab instead of broadcasting across panes or windows.
- Autofix requires a connected helper session. Failures received before the
  session connects are not replayed later.
- Terminal mutation requested by an agent goes through the confirmation-gated
  session MCP action path. Agent-owned shell tools are a separate execution
  path.

## Key files

| Area | Path |
| --- | --- |
| Terminal integration | `src/cascadia/TerminalApp/TerminalPage.cpp` |
| Protocol bridge | `src/cascadia/TerminalApp/TerminalPage.Protocol.cpp` |
| Tab lifecycle and pre-warm | `src/cascadia/TerminalApp/TabManagement.cpp` |
| Agent pane chrome | `src/cascadia/TerminalApp/AgentPaneContent.cpp` |
| Stash/restore | `src/cascadia/TerminalApp/Tab.cpp` |
| Shared WTA process | `src/cascadia/TerminalApp/SharedWta.cpp` |
| COM server | `src/cascadia/WindowsTerminal/TerminalProtocolComServer.cpp` |
| Protocol IDL | `src/cascadia/TerminalProtocol/TerminalProtocol.idl` |
| Agent registry | `src/cascadia/inc/AgentRegistry.h` |
| Settings | `src/cascadia/TerminalSettingsModel/MTSMSettings.h` |
| WTA master/helper | `tools/wta/src/master/mod.rs`, `tools/wta/src/helper/mod.rs` |
| Runtime agent prompt | `tools/wta/prompts/terminal-agent.md` |

## Build and validation

WTA and Terminal use separate build systems. Build WTA before packaging changes
that need a refreshed `wta.exe`.

### WTA

Always use the explicit Windows target. `CascadiaPackage.wapproj` prefers this
output over the host-target fallback, so mixing target layouts can silently
deploy a stale binary.

```powershell
cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
```

Output: `tools/wta/target/x86_64-pc-windows-msvc/debug/wta.exe`.

A live WTA process may lock the output. Stop only processes whose executable
path exactly matches the binary being rebuilt; never terminate every `wta.exe`
or `WindowsTerminal.exe` by name.

### Terminal

```cmd
cmd.exe /c "tools\razzle.cmd && bcz no_clean"
```

For Release use `bcz rel no_clean`. For a project-local incremental build, enter
the project directory in the same razzle CMD session and use `bx`.

After C++, XAML, IDL, packaging, resource, or mixed Debug changes, deploy with:

```powershell
.\build\scripts\Invoke-IntelligentTerminalDebugDeployment.ps1 `
    -AppxRecipePath src\cascadia\CascadiaPackage\bin\x64\Debug\CascadiaPackage.build.appxrecipe
```

Do not perform a full package deployment for a `wta.exe`-only change. Static
assets such as `wt-agent-hooks` do require packaging.

## Runtime data and diagnostics

Packaged state and cache data are package-private:

- State: `Packages\<PFN>\LocalState\IntelligentTerminal`
- Cache/logs: `Packages\<PFN>\LocalCache\Local\IntelligentTerminal`
- Logs: `logs\<package-version>\`

Unpackaged development falls back to
`%LOCALAPPDATA%\IntelligentTerminal`. Resolve paths through the shared runtime
path helpers; do not hard-code `%TEMP%` or a bare LocalAppData path.

Primary logs are:

- `wta-main_master.log`
- `wta-main_helper-{pid}.log`
- `wta-cli.log`
- `wta-delegate.log`
- `wta-probe.log`
- `wta-install-hooks.log`
- `wta-ensure-host.log`
- `wta-acp-debug.log`
- `terminal-agent-pane.log`

Use `WTA_LOG=debug` or `WTA_LOG=trace` for additional Rust tracing. See
`tools/wta/README.md` for current diagnostics and CLI usage.

## Focused design references

- Multi-window helper/master lifecycle:
  `doc/specs/Multi-window-agent-pane.md`
- Session tracking: `doc/specs/hybrid-agent-session-tracking.md`
- Security boundaries: `doc/security-model.md`
- Installer: `doc/building-installer.md`
- WTA customization: `tools/wta/CUSTOMIZATION.md`
