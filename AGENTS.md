# Markdown Rendering in Agent Pane Feature Handoff

> Last synchronized: 2026-08-12
>
> 这个文件只描述 Markdown Rendering in Agent Pane Feature。它应该可以直接复制到新的 dev branch，
> 让下一阶段不需要重新翻阅旧调查记录。实际代码始终是最终 source of truth。

新的 dev/publish branches:

- dev branch：`user/DinahK-2SO/markdown-renderer`, remotely push to "Dinah".
- publish branch：`user/DinahK-2SO/markdown-renderer-publish`, remotely push to "origin".

这两个branch都从`main@0c683a00e`创建。当前follow-up完成后，再下一阶段不要继续基于它们开发：
请从最新`origin/main`开新的dev branch，把本文件copy过去，并在这里记录新branch名称。

如果下一阶段仍使用dev/publish双branch：publish branch用于正式产品代码和code review，dev
branch还可以包含调查、tracking和本地workflow。上一个publish branch不包含：

- `AGENTS.md`
- `doc/`
- `build/scripts/New-LocalMsixInstaller.ps1`
- `test/e2e/selftests/LocalMsixInstaller.Unit.Tests.ps1`
- `test/e2e/selftests/UsageLocalization.Unit.Tests.ps1`
- 本地E2E framework、wire、provider config和未明确选入review evidence的截图

新的branch可以根据任务调整清单，但继续遵守同一个原则：publish只表达当前产品行为，dev可以
保留历史背景和本地workflow。

========================

## 当前follow-up：
[2026-08-12] Step 2 - streaming agent message Markdown GREEN

我们的目标是在agent pane中显示markdown。


我们知道copilot cli和 opencode在terminal中显示的markdown是有渲染的。所以可以学习一下他们是怎么做的（已添加opencode 的代码到 current workspace）。


之前我们组的同事们做过这个field的一点调查，告诉我们要注意几个事情：
1. 记得要测试multiple lines的情况。
2. 记得要测试不同的主题。
3. 注意agent page有自己专属的主题，独立于terminal

### Implementation调查结论

调查过以下路径：

- OpenCode TUI使用OpenTUI的`<markdown streaming>` widget，table使用grid style；Markdown正文、
  heading、link、code、quote、emphasis、strong、list、image和code block各自映射到TUI theme
  token。它在streaming期间用当前完整buffer反复投影，而不是逐chunk保存parser state。
- `tui-markdown 0.3.9`直接把CommonMark/GFM转换成Ratatui `Text`，支持heading、inline
  formatting、list、quote、link、code block、table和wide-character table alignment，并提供
  `StyleSheet` adapter。关闭默认`highlight-code`后不会绑定固定dark syntax theme。
- `termimad 0.35.1`有成熟的width-aware wrapping、table balancing和skin，但自带另一套
  Crossterm rendering/layout ownership，不适合嵌入当前Ratatui chat renderer。
- 直接使用`pulldown-cmark`控制最强，但table、nested block、styled wrapping和Ratatui转换都要
  自己维护；现阶段没有足够收益支持这份重复实现。

Decision：使用`tui-markdown -> WTA StyleSheet -> WTA styled wrapping/prefix -> Ratatui Line`
的数据流。parser和agent pane theme adapter分离；Markdown renderer只归
`tools/wta/src/ui/chat.rs`所有，C++ `TerminalControl`不解析Markdown。

### TDD evidence

Step 1只改变finalized `ChatMessage::Agent`：

- RED：新增`agent_message_renders_multiline_markdown_with_theme_relative_styles`，运行
  `cargo test --manifest-path tools/wta/Cargo.toml agent_message_renders_multiline_markdown_with_theme_relative_styles -- --nocapture`；
  失败为`left: "● # Heading"`, `right: "● Heading"`，证明旧路径没有解析Markdown。
- GREEN：同一命令`1 passed, 0 failed`；`cargo test --manifest-path tools/wta/Cargo.toml ui::chat::tests -- --nocapture`
  为`32 passed, 0 failed`。
- Theme contract：正文和heading以`Color::Reset`为基色，跟随agent pane自己的color scheme；
  code使用reverse，link使用pane ANSI cyan + underline，quote/meta/table border只叠加modifier，
  不读取普通terminal pane theme。
- Dependency compliance：新增`tui-markdown 0.3.9`且关闭default features；已运行
  `Generate-WtaThirdPartyNotices.ps1`更新`Cargo.lock`、`cgmanifest.json`和`NOTICE.md`。
- Commit/push：`27ba52552 Render finalized agent responses as Markdown`已推送到
  `Dinah/user/DinahK-2SO/markdown-renderer`并确认同步。

Step 2让streaming pending buffer复用同一个renderer：

- RED：新增`pending_stream_renders_markdown_and_preserves_partial_syntax`；第一次修正test fixture
  后，同一focused command失败为`left: "● # Heading"`, `right: "● Heading"`。
- GREEN：`cargo test --manifest-path tools/wta/Cargo.toml pending_stream_renders_markdown_and_preserves_partial_syntax -- --nocapture`
  为`1 passed, 0 failed`；chat module为`33 passed, 0 failed`。
- Streaming contract：typewriter仍先用`reveal_chars`切出当前可见buffer，再对整个可见buffer重新
  parse/project。未闭合的`**bo`必须保留已显示的`bo`并且不能panic；finalize仍把完整raw buffer
  存入`ChatMessage::Agent`，不保存parser state。
- Commit/push：`90b2f992c Render streaming agent responses as Markdown`。

下一条RED：GFM table在窄宽度下不能丢行，并且actual rendered lines必须与finalized/pending height
calculation一致；之后为light/dark agent pane theme contract建立RED。


========================

## 在开始下一阶段正式开发前

如果下一阶段会改变provider launch、package、agent routing、Bottom Bar、Usage显示或session
管理，请先确认这些live acceptance仍然可以完成：

1. [empty]
2. build/deploy existing Intelligent Terminal并launch；
3. 截图并确认Terminal窗口visible且nonblank；
4. 点击Bottom Bar按钮展开agent窗口，截图并确认agent对话UI可见；
5. 默认选择的provider是copilot，截图并确认active agent确实active；
6. 与copilot对话要一个table（比如3x3的乘法表， return in table-like, 或者你可以改成更详尽的提示词测试），等待response，然后截图，确认能看到copilot response 的显示效果。

Try to reuse existing tests. 现有framework无法覆盖真实用户操作时，可以在本地开发新的test
framework，但不要把大型新framework放进feature commit。做好modularization，使它未来可以
独立成为新的PR。

本地E2E framework、scripts、wire、provider configs和screenshots不要删除，即使它们被ignore。
需要commit的截图必须复制到非ignored的指定review-evidence目录，否则只在tracking中记录路径和
验证结果。

用PATH中解析到的`pwsh`（PowerShell 7+）做E2E。需要启动同一个host的子进程时，复用：

```powershell
(Get-Process -Id $PID).Path
```

不要硬编码本机PowerShell安装目录。

========================

## Strict Test Driven Development workflow

每一个behavior change必须按以下顺序：

1. 在现有framework中增加或修改最小test，建立RED；
2. 运行focused test，确认它因为预期原因失败；
3. 做最小GREEN implementation；
4. 立即重跑同一个focused validation；
5. 更新新branch的self-contained tracking note；
6. commit产品代码、合适的现有framework tests和tracking；
7. push dev branch；
8. 确认remote同步后才能开始下一个RED步骤。

若push失败、branch分叉或出现无法安全合并的远端提交，停止下一步，先解决同步问题。

注意做好modularization并reuse existing code。若现有架构在多个位置重复定义同类功能，feature
branch先follow existing ownership；大型架构refactoring留到独立branch。不要为了这个feature
创建平行的Usage state/event/UI route。

关于tests是否commit：现有framework能自然cover的tests应该commit；新的本地桌面E2E framework
只保留本地，未来另开framework PR。

========================

## 最终产品设计

### 用户看到什么

the correctly rendered markdown output.

========================

## Feature内部数据流与ownership

```text
ACP AgentMessageChunk
  -> app_turn.rs turn buffer
  -> ui/chat.rs pending_render_text / ChatMessage::Agent
  -> tui-markdown parser
  -> AgentMarkdownStyleSheet (theme.rs semantic styles)
  -> width-aware styled lines + agent dot/hanging indent
  -> Ratatui Paragraph
  -> agent pane TermControl using its own color scheme
```

`ui/chat.rs`必须让实际rendered lines和height calculation共享同一个Markdown转换结果，避免
multiple lines/table/wrapping造成chat area undercount。ACP/master、ChatMessage storage和C++ pane
不保存parsed Markdown AST，也不做provider-specific Markdown transformation。


========================

## Local evidence必须保留

Local desktop orchestration、provider configs、credentials、wire captures、screenshots和custom
mock frameworks不进入feature product commits。不要因为它们被ignore就删除。

Known local artifact families包括：

- `test/e2e/artifacts/*
- etc.

分享或commit任何capture前，检查并清除prompts、credentials、local paths、account identifiers、
tokens和provider logs。

========================

## Review hygiene与历史guardrails

Publish branch 只表达当前behavior：

- 不保留force/ban superseded provider-specific behavior的tests/comments；
- 这是为了降低review cognitive load，不是隐瞒历史；
- 历史原因保留在dev-only handoff/tracking；
- 未来有正式特殊处理时，把verified contract、implementation和tests一起提交；
- 对low-confidence review comment先沿owning code path验证，不直接接受或拒绝。

本PR的review经验：

- CommonMark single newline是soft break，不等于paragraph break；multiple-paragraph test fixture
  必须使用空行，不能把错误expectation固化成renderer contract。
- 不要对本feature运行crate-wide `cargo fmt --manifest-path`后提交全WTA formatting churn；只format
  touched Rust files并检查git status。

Do not accidentally reintroduce：

- finalized message和streaming message使用不同Markdown semantics；下一step完成后两者必须调用
  同一个renderer。
- 使用固定dark syntax theme或hardcoded white foreground，导致light agent pane不可读。
- height estimator继续数raw Markdown characters而actual renderer已经隐藏syntax marker。


========================

## Definition of Done for next follow-up

一个follow-up step完成必须满足：

- behavior符合本contract或明确记录的新decision；
- 有focused RED/GREEN evidence；
- relevant full tests/build通过；
- logs/telemetry不包含Usage values；
- UI copy变化时完成localization/accessibility；
- local E2E evidence保留且敏感/ignored artifacts不误commit；
- dev/publish scope正确；
- commit已push且branch同步；
- 本handoff更新完成，下一branch无需重新调查。


以下是project-wide 的一些background knowledge。仅供参考，请以实际代码实现为准。

=================================================

# Intelligent Terminal (Windows Terminal Fork)

AI-native Windows Terminal — agents (Copilot, Claude, Gemini, custom) can understand, fix, and automate terminal workflows.

## Core Components

- **WTA** (Windows Terminal Agent) — orchestrator binary. Launches agents, passes Terminal Protocol connection info. Agents control WT via `wtcli`.
  - Launch: `wta delegate --agent <agent> --delegate-agent <delegate> --cwd <cwd> "<prompt>"`
- **WT Protocol** (`IProtocolServer`) — sole integration surface. WinRT IDL + COM out-of-process server (MBM marshaling, MTA thread). Discovery via `WT_COM_CLSID` env var.
  - IDL: `src/cascadia/TerminalProtocol/TerminalProtocol.idl`
  - Server: `src/cascadia/WindowsTerminal/TerminalProtocolComServer.cpp`
- **WTCLI** — CLI client consuming `IProtocolServer` via `CoCreateInstance(CLSCTX_LOCAL_SERVER)`. Agents shell out to `wtcli list-panes`, `wtcli capture-pane`, etc.
- **ACP** (Agent Control Protocol) — JSON-RPC 2.0 spoken inside the helper+master architecture. `wta-helper` ↔ `wta-master` over a named pipe; `wta-master` ↔ agent CLI subprocess over stdio. The C++ side no longer participates in ACP directly — agent panes are plain `ConptyConnection`s hosting a `wta-helper` child. See `doc/specs/Multi-window-agent-pane.md`.

## UX

| Trigger | Behavior |
|---------|----------|
| `>Toggle AI assistant` | Opens/toggles agent pane (`openAgentPane` action) |
| `?<prompt>` | Delegates to hidden background WTA process |
| `?` (empty) | No-op |
| `&` | Background task mode (future, C9) |

Agent pane: position configurable (`bottom`/`right`/`top`/`left`). Color-coded VT output.

## Settings (`settings.json`)

```jsonc
{
    "acpAgent": "copilot",           // "copilot", "gemini", or "custom:<cmd>"
    "acpModel": "",                  // Model override
    "acpCustomCommand": "",          // Command for custom agent
    "agentPanePosition": "bottom",
    "delegateAgent": "copilot",      // Agent for ?<prompt> delegation
    "delegateModel": "",
    "delegateCustomCommand": "",
    "autoFixEnabled": true,
    "aiIntegration.coordinator.enabled": false,
    "aiIntegration.coordinator.commandline": "wta",
    "aiIntegration.coordinator.profile": "{fd19208a-412b-4857-8a2d-9ca592b4b16e}",
    "aiIntegration.confirmation.readOperations": "auto",
    "aiIntegration.confirmation.createOperations": "auto",
    "aiIntegration.confirmation.inputOperations": "auto",
}
```

## Architecture

```
WindowEmperor (one WT process, N AppHosts/windows)
  |-- TerminalProtocolComServer (COM, MTA thread, WT_COM_CLSID)
  |-- SharedWta (singleton) -- spawns --> wta-master ──► agent CLI (ACP/stdio)
  |                                          ▲
  |                                          │ ACP/JSON-RPC over named pipe
  +-- AppHost[] → TerminalWindow → TerminalPage
        |-- CommandPalette (? / & prefixes)
        |-- Per-tab agent pane: ConptyConnection ───► wta-helper (conpty child)
        |                                            (one helper per tab, pre-warmed)
        +-- Protocol bridge (TerminalPage.Protocol.cpp)

External: Agent → wtcli → COM (IProtocolServer) → TerminalProtocolComServer → WindowEmperor
```

**Per-tab + per-window routing.** Each agent pane has its own helper bound
to an `owner_tab_id` (= WT tab StableId) and a `window_id`. All inbound
events that mutate per-tab state (`set_agent_state`, `tab_changed`,
`tab_closed`, `tab_renamed`) carry both ids; helpers filter by `window_id`
and (for `tab_changed`) by owner-lock in `switch_tab_session`. Outbound
helper events (`agent_state_changed`, `agent_status`, `autofix_state`,
`close_agent_pane`) carry `tab_id` so C++ can route via
`_FindTabByStableId` instead of fanning out across every pane / window.
See `doc/specs/Multi-window-agent-pane.md` §7.

**Helper is pre-warmed per tab.** Every new tab spawns a stashed agent
pane on creation (`_InitializeTab` → `_AutoCreateHiddenAgentPaneShared`
with `autoStash=true`, `--start-stashed`), so the helper is running and
its ACP session connects in the background from the start — even if the
user never opens the pane. This is what lets autofix work on a tab the
user hasn't interacted with. The agent CLI itself is spawned once by
`wta-master` at startup and shared across all helpers (each helper's
`initialize` is a cached replay; only `session/new` round-trips to the
CLI). `--start-stashed` only seeds `pane_open=false`; it does not defer
the handshake. The pre-warm is skipped when wta is unavailable, GPO
blocks all agents, or the tab arrived with an agent pane via cross-window
drag-in (`agentLeavesSeen > 0`). See `TabManagement.cpp:366`.

**Agent pane toggle = stash, not destroy.** `Ctrl+Shift+.` /
`Ctrl+Shift+/` / the bottom-bar button toggle via
`Tab::StashAgentPane`/`RestoreStashedAgentPane` (built on WT's
`Pane::HidePane`/`RestorePane`). Helper + conpty + ACP session + chat
history all survive the toggle. The pane is only destroyed on tab close
or `Ctrl+C×2` in the TUI. See spec §8.

## Key Files

| Area | Path |
|------|------|
| Agent integration | `src/cascadia/TerminalApp/TerminalPage.cpp`, `TerminalPage.Protocol.cpp` |
| Agent pane wrapper | `src/cascadia/TerminalApp/AgentPaneContent.cpp` (XAML chrome around the helper's `TermControl`) |
| Tab-side stash | `src/cascadia/TerminalApp/Tab.cpp` (`StashAgentPane`, `RestoreStashedAgentPane`, `HasStashedAgentPane`) |
| Command Palette | `src/cascadia/TerminalApp/CommandPalette.cpp` |
| Protocol IDL | `src/cascadia/TerminalProtocol/TerminalProtocol.idl` |
| COM Server | `src/cascadia/WindowsTerminal/TerminalProtocolComServer.cpp` |
| Shared master spawn | `src/cascadia/TerminalApp/SharedWta.cpp` |
| wta-master | `tools/wta/src/master/mod.rs` |
| wta-helper / App | `tools/wta/src/app.rs`, `tools/wta/src/main.rs` |
| Settings | `src/cascadia/TerminalSettingsModel/GlobalAppSettings.idl`, `MTSMSettings.h` |
| Settings UI | `src/cascadia/TerminalSettingsEditor/AIAgents.xaml` |
| Process coord | `src/cascadia/WindowsTerminal/WindowEmperor.cpp` |

## Autofix

Detects command failures in other panes and auto-suggests fixes via the agent.

**Pipeline**: Shell emits `OSC 133;D;<exit_code>` → `TerminalPage` raises `ProtocolVtSequenceReceived` → COM server forwards to clients → WTA (via `wtcli listen --json`) classifies → `maybe_trigger_autofix()`.

**Requirements**: PowerShell shell integration (OSC 133 marks), a helper
whose ACP session has reached `Connected`, `wtcli` on PATH. The pane does
**not** need to be visible — the per-tab pre-warmed helper (see
Architecture) makes autofix work on a stashed pane. But a failure that
lands before the helper's session connects (cold start of master/agent
CLI, in-flight `session/new`, or a `Failed` agent) is **dropped**:
`trigger_autofix_inner` early-returns when `state != Connected`
(`app.rs:6820`). The bottom-bar notification banner still shows; only the
autofix pill / LLM call is skipped, and the failure is not re-triggered
once the session later connects.

**Key code**: `tools/wta/src/app.rs` (`classify_wt_event`, `maybe_trigger_autofix`), `TerminalPage.cpp:2650-2740` (event handlers), `TerminalProtocolComServer.cpp` (`_ensurePageEventsRegistered`).

**Diag log**: `wta-ensure-host.log` in the WTA log directory — shows event flow, classification, and autofix triggers.

## Hooks plugin auto-upgrade

When IT is installed or upgraded, the bundled `wt-agent-hooks` plugin
(`tools/wta/wt-agent-hooks/{copilot,claude,gemini-extension}/`) needs to
re-land into any agent CLI the user already opted into (via Settings UI /
FRE "Install hooks" or `wta hooks install`). This is handled silently by
`agent_hooks_installer::upgrade_installed_hooks`, fired once per
`wta-master` startup on a blocking-pool thread.

**Trigger model — bundle version is the upgrade signal.** A tiny state
file `<LocalCache>/IntelligentTerminal/hooks-upgrade-state.json` records
the bundle version this wta process last saw per CLI. At startup we read
each CLI's bundle `plugin.json` / `gemini-extension.json` (cheap, <5ms)
and compare; if all match, we return immediately (no spawns, no IO
beyond the cache compare). Only after the user installs / upgrades IT
does the bundle version change → cache miss → per-CLI flow runs once,
then the state file is rewritten and the fast path resumes.

**Opt-in only.** Even on cache miss, CLIs that don't already have
`wt-agent-hooks` installed are skipped. The auto-upgrade never installs
into a CLI the user hasn't accepted. Disabled plugins are also skipped
(`enabled: false` in Copilot's `config.json` / `claude plugin list`).

**Per-CLI strategy.** Copilot and Claude use their `plugin update`
subcommands; before invoking them we rewrite any stale marketplace
`source.path` to the current bundle dir (Copilot: existing
`cleanup_stale_copilot_marketplace`; Claude: new
`cleanup_stale_claude_marketplace`). Gemini's `extensions update`
silently returns `NOT_UPDATABLE` when the recorded install source no
longer exists (typical after an MSIX version-dir bump), so we peek at
`~/.gemini/extensions/wt-agent-hooks/.gemini-extension-install.json`
first: if `type==local` AND `source` is still under the current bundle,
run `extensions update` in place; otherwise fall back to
uninstall+install while preserving the `isActive` flag.

**Trigger-point caveat.** The agent CLI master spawns concurrently may
already be past its plugin-load step by the time `plugin update` writes
the new files — so the freshly upgraded hooks may not take effect until
the next agent restart. Acceptable because blocking master startup on a
Node-based `plugin update` (1-30s) would hurt every IT-upgrade boot.

**Diag**: `wta-install-hooks.log` (existing) plus `target=agent_hooks`
+ `target={copilot,gemini}_hooks` trace events in
`wta-main_master.log` show every per-CLI decision (`upgrade decision`
log line carries `installed_version`, `bundle_version`, `action`).

## Logs & runtime data layout

WTA runtime data lives under the **package-private** store, split by lifetime
into two roots (both resolved in `runtime_paths.rs`, both falling back to the
same bare path when the process has no package identity):

```
# Packaged (every production wta process — helper is a conpty child of the
# packaged WindowsTerminal.exe, master is spawned in-package by SharedWta):

  …\Packages\<PackageFamilyName>\LocalState\IntelligentTerminal\   <- STATE root
      prompts\                      (prompt overrides)             intelligent_terminal_root()
      agent-pane-sessions.jsonl     (session origin index)
      master-pipe.txt               (helper↔master rendezvous)

  …\Packages\<PackageFamilyName>\LocalCache\Local\IntelligentTerminal\  <- LOCAL/cache root
      logs\<pkgver>\                (ALL logs for that build — Rust wta-*.log,
                                     C++ terminal-agent-pane.log, PS hook-trace.log)
      hook-bundle-staging\ …        (hook-installer staging)
      hooks-upgrade-state.json      (per-CLI bundle version cache for the
                                     hooks auto-upgrade fast-path)

# Unpackaged (dev builds run straight out of the Cargo target dir, tests):
# BOTH roots collapse to the legacy bare %LOCALAPPDATA%\IntelligentTerminal\.
```

Rationale for the split: **State** = persistent, must-survive, package-private
data → `LocalState` (alongside the WT app's own `settings.json` / `state.json`).
**Local/cache** = transient, regenerable diagnostics → `LocalCache\Local`, the
cache store that doesn't roam / back up.

Both roots are package-private — removed on uninstall and isolated between the
dev-sideload family (`IntelligentTerminal_rd9vj3e6a2mbr`) and the store family
(`Microsoft.IntelligentTerminal_8wekyb3d8bbwe`) — instead of sharing one bare
`%LOCALAPPDATA%\IntelligentTerminal` directory. The family name comes from
`GetCurrentPackageFamilyName` (windows-sys); the `Packages\<pfn>\LocalState` and
`…\LocalCache\Local` paths are what WinRT `ApplicationData.Current.LocalFolder`
/ `LocalCacheFolder` resolve to, so we construct them directly rather than
pulling in the WinRT projection.

**All three writers share one per-version dir** `logs\<pkgver>\`, where
`<pkgver>` is the **package version** (`GetCurrentPackageId`, e.g. `0.8.0.2`) —
read identically at runtime by Rust (`logging::package_version`) and C++
(`IntelligentTerminal::PackageVersionDir`), so no build-time version sync is
needed:
- Rust wta processes → `logging::log_dir()` (`logs\<pkgver>\wta-*.log`).
- C++ `AgentPaneLog.h` → `IntelligentTerminal::LogDirVersioned()` →
  `terminal-agent-pane.log` (renamed from the old `wta-agent-pane.log`).
- PowerShell hooks (`send-event.ps1`) → `hook-trace.log`, via the
  `WTA_HOOK_LOG_DIR` env var set to `LogDirVersioned()` (C++ ConptyConnection
  for shell panes; `spawn.rs` for agent-pane CLIs).

`IntelligentTerminal::LogDir()` stays the **root** (`…\logs`, no version) and is
used only by the bug-report-zip action so it archives every version at once.
Unpackaged (dev-from-cargo / tests) has no package identity → all writers fall
back to the flat bare `…\logs\`.

> Earlier builds wrote everything to the bare `%LOCALAPPDATA%\IntelligentTerminal`
> regardless of identity (the `LOCALAPPDATA` env var is **not** redirected into
> the sandbox on Win10/11). There is no migration — old data is left in place
> and simply ignored.

**Log level** is controlled by the `WTA_LOG` (or `RUST_LOG`) env var. When
unset, the default comes from the build: **debug builds default to `debug`,
release builds default to `info`** (`logging::default_filter_directive`). Set
`WTA_LOG=debug|trace` for the noisy traces, or `WTA_LOG=warn` to quiet a
release build further.

**Logging is initialized once** in `main()` immediately after arg parsing
(`logging::init(&process_label(&cli))`), before locale/ETW setup, so even
early-startup failures land on disk. The non-blocking appender's `WorkerGuard`
lives in a global and is flushed via `logging::shutdown_flush()` on every exit
path — including before each `std::process::exit` (which would otherwise skip
the guard drop and lose buffered records). Every launch mode — including
short-lived `wtcli`-style commands — now writes a log file (previously only 6
entry points did).

**Per-version storage + retention** (`logging::housekeeping`): each build's
logs live in their own subdir, `logs\<pkgver>\` (the package version — see
above). On every start, `prune_old_version_dirs` keeps **only the current
version's dir** and deletes all other version dirs wholesale. The current
version's dir is never a deletion target, so cleanup is **lock-free and
concurrency-safe** (no process can delete a file another is writing). Within the
current version's dir, per-PID helper logs older than **3 days** are pruned and
`wta-cli.log` rotates daily keeping 3 days (`max_log_files`).

### Log files in the helper+master architecture

```
wta-main_master.log        — wta-master process: agent CLI spawn, named pipe accept
                              loop, per-helper routing, session_to_helper map updates,
                              agent CLI exit detection, connection failures
wta-main_helper-{pid}.log  — each wta-helper process (one file per PID, so concurrent
                              per-tab helpers don't interleave): pipe connect, ACP
                              initialize, session/new, prompts, agent responses,
                              TUI lifecycle, connection failures
wta-cli.log                — short-lived wtcli-style commands (list-*, capture-pane,
                              listen, sessions, …); daily-rotated, 3-day retention
wta-delegate.log           — `?<prompt>` delegation flow (separate from agent pane)
wta-probe.log              — `probe-models` ACP model-list probe
wta-install-hooks.log      — `hooks install` agent-hook bridge installation
wta-ensure-host.log        — WT-side background ensure-running diagnostics (kept from
                              M3-M6 era; remains useful for SharedWta lifecycle)
wta-acp-debug.log          — low-level ACP JSON-RPC wire trace
```

Two files in the per-version dir are **not** written by the Rust wta binary —
`hook-trace.log` (PowerShell hooks) and `terminal-agent-pane.log` (C++ side);
see **All three writers share one per-version dir** above. They live in the
same `logs\<pkgver>\` and so are cleaned together with the Rust logs when that
version's dir ages out.

### Tracking flows by `target` field

All tracing uses structured `target` + key=value fields. Grep patterns for common
scenarios:

| Goal | Grep |
|---|---|
| Master process lifecycle | `target=master` (in `wta-main_master.log`) |
| Who's connected to master right now | `live_helpers=` in `wta-main_master.log` (climbs on connect, drops on disconnect) |
| Which helper owns a SessionId | `step="helper→agent" op="new_session" session_id=…` |
| Trace one prompt end-to-end | grep `session_id="X"`, look for `step="helper→agent" op="prompt"` (sent) then `step="master→helper" op="session_notification"` (response chunks) |
| Helper pipe lifecycle | `target=master helper_id=…` shows connect+exit |
| Agent CLI failures | `target=agent_stderr` |
| Connection failures (either side) | `"exiting with error"` — `target=master` in `wta-main_master.log`, `target=helper` in `wta-main_helper-{pid}.log`; plus inline `step="acp_initialize"` / `step="pipe_connect"` for the helper handshake |
| Internal control routing | `target=internal_control` (legacy; mostly empty post-Z) |

### Example: end-to-end trace of one user prompt

```
[helper] target=acp_client                — pipe connected to master
[helper] target=acp_client                — ACP initialize sent
[helper] target=acp_client                — session/new → session_id=abc-123
[master] step=helper→agent op=new_session — registered abc-123 → helper_id=2
[helper]                                  — user pressed Enter, sending prompt
[master] step=helper→agent op=prompt      — forwarding to agent CLI (sid=abc-123)
[master] step=agent→helper kind=agent_message_chunk — agent CLI streamed first chunk
[master] step=master→helper               — wrote chunk back to helper_id=2 pipe
[helper]                                  — chunk applied to TabSession.messages
[master] step=helper→agent op=prompt elapsed_ms=842 stop_reason=…  — turn ended
```

If any step is missing, the failure is at the previous step.

## Build

There are two independent build systems. **Both must be built** before F5.

### 1. WTA (Rust) — build first

```bash
# Kill stale WTA processes first
taskkill //f //im wta.exe 2>/dev/null; true

cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
# Output: tools/wta/target/x86_64-pc-windows-msvc/debug/wta.exe
#
# Always pass --target explicitly — the wapproj prefers
# tools/wta/target/<triple>/<profile>/wta.exe over the bare target/<profile>
# fallback, and a stale explicit-target binary will silently shadow your
# fresh bare-target build.
```

### 2. Terminal (C++ / MSBuild)

**Command line (incremental):**
```bash
cmd.exe //c "tools\razzle.cmd && bcz no_clean"
# Release: bcz rel no_clean
# Output: bin/x64/Debug/
```

**Visual Studio F5 (debug):**
- Set `CascadiaPackage` as startup project → F5
- MSBuild copies `wta.exe` from Cargo output into the package layout
  (via Content items in `CascadiaPackage.wapproj`)
- The deployed `wta.exe` sits next to `WindowsTerminal.exe` in the
  package directory, inheriting package identity for COM access

### Safe Debug deployment

After a Debug Terminal build, use this wrapper to deploy C++, XAML, IDL,
`wtcli`, manifest, resource, packaging, or mixed changes:

```powershell
.\build\scripts\Invoke-IntelligentTerminalDebugDeployment.ps1 `
    -AppxRecipePath src\cascadia\CascadiaPackage\bin\x64\Debug\CascadiaPackage.build.appxrecipe
```

The script validates the dev package and loose Debug layout, closes only exact
PIDs running from that layout, deploys it, and reopens Intelligent Terminal if
needed. It terminates IT panes and agent sessions but never ordinary Windows
Terminal. Never stop `WindowsTerminal.exe` by name; use `-WhatIf -Verbose` when
process selection is uncertain.

Do not use full deployment for `wta.exe`-only changes; use the WTA hot-refresh
flow. Static assets such as `wt-agent-hooks` are not `wta.exe`-only changes.

### Full rebuild flow (typical dev cycle)

```bash
# 1. Build WTA (always use --target — see note above)
taskkill //f //im wta.exe 2>/dev/null; true
cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml

# 2. Build & run Terminal from VS
#    F5 in Visual Studio (CascadiaPackage project)
#    — or from command line:
cmd.exe //c "tools\razzle.cmd && bcz no_clean"
```

### Package identity & COM

The COM server (`TerminalProtocolComServer`) is registered under the
Terminal's package identity. `wtcli.exe` and `wta.exe` must also have
package identity to activate it via `CoCreateInstance`. This is why:

- `wta.exe` is deployed **inside the package** (next to `WindowsTerminal.exe`)
- `_DetectWtaPath()` prefers the co-located `wta.exe` over dev-build paths
- Running `wta.exe` from `tools/wta/target/debug/` directly will fail with
  `0x80073D54` (APPMODEL_ERROR_NO_PACKAGE) when calling COM methods

If autofix or the agent pane stops working after a debug launch, check
`%TEMP%\wta-ensure-host.log` for the `0x80073D54` error — it means
the wrong (unpackaged) `wta.exe` was used.

## Installer

See **[doc/building-installer.md](doc/building-installer.md)** for full details.

Two distribution formats:

| Format | Script | Output |
|--------|--------|--------|
| **MSIX ZIP** (packaged) | Manual assembly from MSBuild output | `artifacts/local-installer/*-msix.zip` |
| **Self-extracting EXE** (unpackaged) | `build/scripts/New-WtaLocalInstaller.ps1` | `artifacts/local-installer/*-setup.exe` |
