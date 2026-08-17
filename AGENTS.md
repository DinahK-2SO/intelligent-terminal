# 历史对话点击交互交接

> Last synchronized: `2026-08-17`
>
> 本地开发区已完成 triangle + user-input 鼠标交互：点击历史 turn 的 `▶` / `▼`
> 或 user-input 实际渲染区域，都可以选中并展开或折叠该 turn。产品行为与已提交
> 测试仍是最终事实来源。

Branches created from `origin/main@8dfcf91935032e1d6cb9f056f32bcf67329651ad`:

- dev: `user/DinahK-2SO/mouse-interactions` -> `Dinah`
- publish: `user/DinahK-2SO/mouse-interactions-publish` -> `origin`
- issue / pull request: `暂无；创建后补充`

Publish scope excludes this handoff and local-only screenshots, reports, logs,
and experiments. 本功能当前没有额外 publish scope 例外。

### Commit and worktree discipline

- Publishable changes are committed first on dev as one self-contained commit:
  product code, product/Rust tests, tests that live naturally in the existing
  ItE2E framework, their deterministic fixtures, and release-checklist/ItE2E
  metadata.
- Dev-only changes are committed separately afterward: this `AGENTS.md`
  handoff, progress notes, ignored screenshots/reports/logs, local-only test
  orchestration, and experiments that do not belong to an existing framework.
- The publish worktree must directly cherry-pick the dev publishable commit. Do
  not cherry-pick a mixed commit and then restore dev-only files.
- Current publishable commit: `954132ebdc6e2bbb31e1b617365203e3b3c9b12d`.
- Current publish head: `7cb94900132f8e3442cbe8e5d9da9d610b2f63da`.
- Excluded work: `reply/details、completed-turn 分隔空行及其他非 user-input UI
  仍不属于 click target；本次新增 hand pointer、整条 prompt row 与 input dialog
  focus recovery，但不显示动作提示文字、underline 或 mouse-only selection state`.

### E2E Reuse and Test-Framework Modularization

- Reuse or extend existing tests, fixtures, helpers, and E2E frameworks first.
  当前最近的可复用覆盖是 `test/e2e/tests/Feature.AgentMouse.Tests.ps1`，
  以及 `Send-AgentMouseEvent` / `Send-AgentMouseClick`。它们已经通过
  ConPTY 注入真实 SGR mouse input，足以覆盖第一版用户操作。
- When the existing framework cannot exercise the real user operation, a local
  E2E framework or orchestration layer may be developed to establish RED/GREEN
  evidence. 第一版不需要新建本地 E2E framework；若后续发现现有能力不足，
  新 framework 必须保持模块化并单独提取为 PR。
- Do not include a large new test framework, general-purpose harness rewrite,
  or unrelated infrastructure in the feature/fix publishable commit. Commit
  only tests that fit naturally in an existing framework; track the modular
  framework extraction under 上述 Excluded work，并使用独立 branch/PR。
- Small deterministic fixtures or helpers may ship with the feature when they
  are narrowly owned by the existing test suite and are required to make the
  regression reliable.

### Public PR review workflow

- For public GitHub PRs, review without authentication by reading these public
  REST endpoints with the webpage fetch tool: `/pulls/<n>`,
  `/issues/<n>/comments`, `/pulls/<n>/reviews`, `/pulls/<n>/comments`,
  `/pulls/<n>/files`, and the HEAD commit's `/check-runs` endpoint.
- Review bodies can contain `<details><summary>Suppressed comments</summary>`;
  treat every suppressed finding as review input and triage it explicitly.
- Do not use `gh`, GitKraken, or another tool that requires GitHub login for a
  public read-only review. Anonymous API/web access cannot reply to or resolve
  threads; report that limitation instead of requesting credentials.
- Every accepted behavior change follows RED -> minimal GREEN -> focused/full
  validation. Before any fix commit is pushed to the PR, run the related live
  E2E from the publish worktree against the exact publish-built and deployed
  binary, and verify source/deployed SHA-256 equality. Set
  `ITE2E_PACKAGE=Dev`; the harness default `Auto` prefers an installed Store
  package and can otherwise validate the wrong binary.

## Current Stage

`2026-08-17`: 第二阶段交互细节已完成 exact publish GREEN：所有可触发 completed-turn toggle
的可见 prompt rows 在 hover 时显示 hand pointer；整条 row 均可点击。点击 input
dialog 会清除历史 turn selection 并恢复输入导航焦点。不显示“点击折叠/点击展开”
提示文字、hyperlink underline、hover background 或 mouse-only selection state。
publishable commit 已从 dev 直接 cherry-pick 到 clean publish worktree，并在该 exact
commit 上完成 full WTA、mixed build、binary hot-refresh/hash、host tests、packaged
E2E 与 C264 验证。

### User-Visible Contract

- 用户左键单击可见历史 turn 的任一 user-input prompt row 时，展开或折叠对应
  turn；`▶` / `▼`、`> ` prefix、prompt 文本及该 row 内未被文字占用的剩余空白
  都属于同一个 click target。
- Prompt-row hit region 横向覆盖 chat content area 的完整可见宽度，纵向仅覆盖该
  turn 实际渲染出的 prompt rows。reply/details、trailing marker、turn 间分隔空行、
  recommendation/permission、hint/activity、input dialog 和其他 UI 均不得误触发。
- 展开状态下，原始多行 prompt 的每一条实际文本行，以及因窗口宽度自动换行后
  的每一条可见 prompt row，都属于同一个 turn 的 user-input hit region。
  原始 prompt 中显式存在的空行也属于该 turn 的 prompt-row target；不可见、被
  viewport 裁掉或已折叠隐藏的原始 rows 不产生 hit region。
- 折叠状态下，仅当前实际渲染的一条 summary row 整行可点击；被截断或未渲染的
  原始文本不产生不可见 hit region。
- 鼠标移动到任一当前可触发 toggle 的 prompt row 时，OS pointer 必须切换为 hand
  cursor。不得显示“点击折叠/点击展开”或其他动作提示文字，也不得因承载 action
  metadata 而显示常驻或 hover underline。Pointer movement 本身不得 toggle、select
  或改变文本选择；离开 target、PointerExited、scroll/resize、tab/view 切换及 stale
  frame 必须恢复默认 pointer。
- Mouse Down 与 Mouse Up 必须命中同一 turn 的有效 click target，且过程中没有
  drag，才算一次有效点击。任何 Drag 都归文本选择，不得 toggle turn。
- 成功点击 triangle 或 user-input 后，该 turn 必须成为当前
  `selected_completed_turn_idx`，并使用与 Tab + Up/Down 键盘选择完全相同的
  高亮和选中样式；不得另建一套 mouse-only selection 状态或视觉样式。
- 鼠标选中后，现有 Up/Down 必须从该 turn 继续导航，Esc 必须清除选择，Enter
  必须复用 `toggle_selected_completed_turn` 对当前选中 turn 再次展开/折叠。
- 点击 completed-turn row 不得改变 agent pane 的 XAML focus；input caret、
  recommendation/card focus 与其他键盘交互保持既有语义。
- 当历史 turn 已被 mouse 或 keyboard 选中时，左键单击当前可见且可输入的 input
  dialog（包含 `Ask anything, / for commands...` placeholder 的边框区域）必须清除
  `selected_completed_turn_idx` 并恢复既有 input navigation focus。该 click 不提交、
  不插入字符、不触发 completed-turn toggle；随后普通字符输入必须进入当前 draft。
- 鼠标拖拽、双击/三击文本选择、Ctrl+C 复制和滚轮滚动保持不变。
- 双击/三击 user-input 后，最终展开状态不得因多击序列发生变化；若实现需要
  延迟单击确认或复用 multi-click classification，必须用 focused test 锁定。
- 滚动、换行、窗口 resize 后，只允许当前实际可见的 triangle/user-input
  cells 响应点击；旧 frame 的 hit region 必须安全失效。
- Hand pointer 必须复用 TerminalControl 的 pointer/hyperlink lifecycle；action metadata
  仅用于定位当前 action，不得显示 hyperlink underline，也不得被 Ctrl+Click 或
  mark-mode Enter 当作可导航 URI 打开。WTA 不接收 OS PointerMoved，也不得因每个
  Moved event 高频重绘；OutputIdle/PointerExited 负责刷新或清理 stale hover state。

### Current Ownership Hypothesis

```text
SGR mouse Down / Up from ConPTY
  -> event.rs::map_crossterm_event
  -> AppEvent::Mouse / app_events.rs
  -> chat render 生成的可见 full-row turn hit regions + input dialog bounds
  -> TabSession 按 turn index 选择/展开/折叠，或清除 selection 恢复 input focus

current-frame action metadata
  -> TerminalControl hyperlink hover lifecycle
  -> hand pointer + PointerExited cleanup; renderer suppresses action-link underline
```

- Owning code path: `ui/chat.rs` 已负责可见 triangle hit；extension 仍由该 render
  path 根据最终 buffer 建立 user-input 实际文本 cell ranges，`app_events.rs`
  负责鼠标手势与 multi-click/drag 协调，`TabSession` 继续负责 turn 展开状态。
- Falsifiable hypothesis: 若把每个可见 turn 的实际 prompt rows 扩大为完整 chat
  content width，并把同一 rows 作为 action hyperlink metadata 输出，整行 click 与
  hand pointer 可以共享同一 render geometry，同时 renderer 可按私有 action URI 抑制
  hyperlink decoration；input dialog bounds 则可在同一 frame 单独记录并复用既有
  selection clear helper，而不扩大到 details 或破坏 drag。
- Cheapest discriminating check: render 一个包含显式换行、显式空行与自动换行的
  completed turn；每条实际 prompt row 都产生 full-width hit/action metadata，点击
  prefix、文本、行尾空白和显式空行都 toggle 同一 turn，而 details/分隔行不
  toggle。mouse-selected turn 后点击 input dialog 必须清除 selection，随后输入字符
  写入 draft。PointerExited/scroll/resize/tab/view 变化后 action hover 必须失效；
  hand pointer 与无 underline 由用户在 exact deployed build 上手动验证。

### Reproduction and RED Oracle

Framework / fixture: 继续复用 `Feature.AgentMouse.Tests.ps1`、ItE2E 的
`Send-AgentMouseClick` / `Send-AgentMouseEvent` 和现有 deterministic ACP
fixture；不新建 framework。

1. 使用 `Start-Terminal -Package 'Dev'` 启动 exact triangle-only baseline，并创建
  一个包含唯一第一行与第二行 marker 的多行 completed turn。
2. 证明该 turn 初始为展开状态、两条 prompt 文本行与 reply 均可见，并记录第二条
  prompt 文本行的一个实际 cell 坐标；保存 RED 截图。
3. 通过 ConPTY 向第二条 prompt 文本行发送完整左键 click，再捕获 pane。
4. 证明 setup preconditions：目标 pane/session 正确、turn 已完成、目标三角形
  可见、fixture prompt exactly once、实际运行 binary 与 baseline hash 匹配。
5. 将截图、pane capture、fixture log 和命令记录在
  `test/e2e/artifacts/mouse-interactions/`。

- Extension RED oracle: 点击多行 user-input 的第二条实际文本行后，turn 仍保持
  展开，因为 triangle-only baseline 没有 prompt-text hit region。
- Expected failure location/message: 新 E2E 应只在“点击第二条 prompt line 后
  details 仍可见”的最终行为断言失败；triangle click 仍必须 GREEN，setup、连接、
  marker 定位与多行渲染必须先通过。
- Extension setup evidence: deterministic prompt 使用唯一
  `SCROLL_TURN_00_<guid>` / `MOUSE_INPUT_SECOND_<guid>` markers；triangle-only
  baseline/publish SHA-256 为
  `FFFE6830C9C8B15E6D88F8148BA1B3218A3610747821CF5BA73B8608118CC56E`。
  setup、fixture exactly-once、multiline visible 与 target coordinate 均通过，
  最终只失败于 `clicking the second rendered prompt line must collapse the completed turn`。

### Implementation

已在正常 chat render 后从实际 buffer 建立当前帧可见 triangle cell 到 turn index
的映射。App 保存 `{tab_id, hit}` Down target；Key、Drag、wheel、resize、focus
change、tab switch 都取消 press。Mouse Up 仅在同一 tab、同一坐标、同一 turn
仍为当前可见 hit 时调用直接按 index toggle。

Functional extension 已将 triangle point map 泛化为带 kind/range 的 current-frame
hit regions。`ui/chat.rs` 从实际 completed-turn render geometry 产生每条可见 prompt
row 的 full-width range，覆盖 prefix、正文、行尾空白、显式空行、自动换行、wide
cells 与 collapsed summary，并排除 details、分隔行和其他 UI。

- Owning abstraction: `ui/chat.rs` 生成可见 hit regions；`ui/layout.rs` 每帧先
  清空旧 map；`app_events.rs` 路由 gesture；`TabSession::toggle_completed_turn`
  复用既有展开状态。
- State or API changes: App 新增当前帧 hit map、action-link rows、input bounds 与 pressed
  target；`TabSession` 新增按 index toggle/input-focus helper；没有 WTA Moved state。
- Extension state/API: `CompletedTurnHitRegion` 统一 triangle/user-input targets；
  `TabSession::select_completed_turn` 与既有 toggle/navigation helpers 统一更新
  `selected_completed_turn_idx`。`TextSelection` 继续拥有 multi-click classification，
  并在 500ms 序列内保留首击 frame buffer，确保第一击折叠后第二/三击仍能完成原
  multiline row 的 word/line selection；没有 mouse-only selection 或 hover state。
- Preserved invariants: 键盘 selection 与 Enter、文本选择、多击、复制、滚轮、
  手动 scroll offset、其他 card/input 交互均不改变。
- Performance implications: WTA 不接收 PointerMoved；正常 render 后只给少量可见
  prompt rows 附加无视觉 decoration 的 action hyperlink metadata。TerminalControl 复用
  本地 hovered-cell lifecycle，OutputIdle/PointerExited 清理 stale metadata，不增加
  持续 hover animation。
- Rejected alternatives and rationale: 不允许 TerminalControl 通过 glyph/prefix 文本
  猜测哪些 rows 可点击；WTA render geometry 是 target ownership 的唯一事实来源。
  不允许每个 Moved 全帧 redraw，也不允许全 pane/详情行热区；用 current-frame
  prompt-row metadata 和 host 既有 PointerExited lifecycle 控制范围与性能。

### TDD and Validation Evidence

- Focused RED: `clicking_completed_turn_triangle_toggles_details` 在 baseline 上
  失败于 `clicking the rendered triangle must collapse the completed turn`。
- Live / E2E RED: `CompletedTurnMouse` setup 全部通过，仅 collapse oracle 失败；
  RED Pester `0 passed, 1 failed`。
- Focused GREEN: 4 个 `completed_turn_triangle*` tests 全部通过，覆盖 direct
  toggle、prompt/mismatched-Up/drag no-op、hidden view/overlay/resize/wheel/tab
  cancellation、visible scrolled hit rebuild、prompt 自带 triangle glyph 和 keyboard
  selection preservation。
- Neighboring tests: `mouse_` 7/7、`completed_turn` 11/11 通过；两个既有
  Copilot-based AgentMouse cases 在 feature 与 exact main baseline 上都因各自 setup
  / oracle 不稳定而失败，A/B 证明不是本功能回归。
- Full suite: dev 与 exact publish 均为 `1510 passed, 0 failed`。
- Explicit-target build: Debug x64 build 成功；50 个既有 dead-code/private-interface
  warnings。
- Exact deployed package: `IntelligentTerminal_0.8.0.2_x64__rd9vj3e6a2mbr`，
  loose Dev AppX；新 E2E 自身固定 `Start-Terminal -Package 'Dev'`。运行中
  `WindowsTerminal.exe`、master 与 helper 均来自该 AppX path，未使用 Store/Auto。
- Source/deployed SHA-256: exact publish source、deployed file、live master/helper
  均为 `FFFE6830C9C8B15E6D88F8148BA1B3218A3610747821CF5BA73B8608118CC56E`。
  Dev worktree 最终验证 build 曾匹配
  `49318CB781C50A6CFB345814C3CFAA80216814209BCE9905F65727F979EBE17F`。
- Packaged E2E: exact publish `CompletedTurnMouse` 1 passed, 0 failed；覆盖
  展开→折叠→重新展开、prompt click no-op 与 drag no-op。首次 publish run 因
  已知双 helper startup race 在 BeforeAll timeout，未执行 click；清理后相同 case
  通过。C264 在 isolated release report 中为 `[x]`。
- Screenshot paths: `test/e2e/artifacts/mouse-interactions/red/` /
  `test/e2e/artifacts/mouse-interactions/green/`。
- Visual inspection: RED before/after 均保持 `▼` 且 reply 可见；GREEN 点击后
  为 `▶` 且 reply 隐藏，再点击恢复 `▼` 与 reply。所有截图 pane 非空，输入区
  稳定，无 overlap/clipping。
- Remaining test gaps: 既有 Copilot-based wheel/selection E2E 当前 baseline 也不
  稳定；另有已记录的 Start-Terminal 双 helper startup race，曾导致一次 BeforeAll
  timeout，清理进程后同一 deterministic case 通过；两者均不在本 feature scope。

- Extension focused RED: `clicking_multiline_completed_turn_prompt_selects_and_reuses_enter_toggle`
  只失败于 second prompt row click 未折叠；`0 passed, 1 failed, 1510 filtered out`。
- Extension focused GREEN: `completed_turn` 16/16、`mouse_` 8/8；覆盖显式多行、
  自动换行、内部空格、collapsed summary、wide cells、prefix/行尾空白/details no-op、
  drag/stale cancellation、keyboard 同款 cyan selection、Enter/Up/Down/Esc，以及跨 frame
  double/triple-click 状态恢复与 word/line selection。
- Extension full WTA: `1515 passed, 0 failed, 0 ignored`，零 warning；semantic replay
  后再次完整通过。Debug x64 explicit-target build 成功；50 个既有
  dead-code/private-interface warnings。
- Extension Dev identity: `IntelligentTerminal_0.8.0.2_x64__rd9vj3e6a2mbr`
  loose Debug AppX；source/deployed `wta.exe` 均为 32,426,496 bytes，SHA-256
  `64CE78287521B13680361424E5F3BBA25FD94026BFBC4DCEF95546B549AC4558`。
- Extension exact publish identity: publish source/deployed `wta.exe` 均为 32,426,496
  bytes，SHA-256
  `EFA9450F9927E361CE4941B7EACB812AF9119B3D23310B8084339D173DD39B30`；publish
  worktree full WTA `1515/1515`、explicit-target Debug build 与 packaged E2E `2/2`
  全部通过。
- Extension packaged GREEN: `CompletedTurnMouse` 2 passed, 0 failed, 0 skipped；
  triangle collapse/re-expand 与 multiline second-row click collapse + Enter re-expand 均
  通过。首次 combined run 的第二 case 因前一 case 合法保留 mouse-selected turn 而无法
  输入 setup prompt；case 开头用既有 Esc 语义清除 selection 后 2/2 GREEN。
- C264 在 fresh isolated release report 中为 `[x]`。`extension-green` before/collapsed/
  Enter screenshots 均非空；collapsed row 使用 keyboard 同款 cyan selection，三帧输入区
  与分隔线稳定，无 overlap/clipping。

- Second-stage focused GREEN: `completed_turn` 17/17；action overlay 3/3，覆盖整条
  prompt row、显式空行、尾部空白、wide-cell tail 跳过及 cell symbol/style 保持；
  TerminalControl action tests 3/3，覆盖 action URI 分类、action underline suppression、
  Ctrl+Click VT mouse forwarding 与不导航。
- Second-stage full WTA: `1520 passed, 0 failed, 0 ignored`，零 test warning；
  explicit-target Debug build 成功。51 个 build warning 均为既有 dead-code/private-
  interface warning；额外计数来自 HEAD 已存在且未被本功能触及的 `app.rs::truncate`。
- Second-stage mixed Debug package build: `169 warnings, 0 errors`。Dev loose package
  `IntelligentTerminal_0.8.0.2_x64__rd9vj3e6a2mbr` 部署成功；Cargo/deployed `wta.exe`
  均为 32,459,776 bytes，SHA-256
  `2997759B13396EBCBF411FD05A43EDB0C2DC0382DBF81B09F20ADD3847AB219D`；
  build/deployed `Microsoft.Terminal.Control.dll` 均为 14,460,416 bytes，SHA-256
  `21DCE666E36EFB790F6BC5F509E9C6A6A1EC418D685333A7185A4019EBDEC5D3`。
- Second-stage packaged GREEN: deterministic `CompletedTurnMouse` 2 passed, 0 failed,
  0 skipped；覆盖 triangle、prefix、整行尾部空白、显式多行、drag、Enter 复用，以及
  点击 input dialog 后 draft/caret 恢复。Fresh C264 report 为 `[x]`。
- Second-stage exact publish identity: publish Cargo/deployed `wta.exe` 均为
  32,459,776 bytes，SHA-256
  `EF4FE97C28CC47E5FC79D494C077201870D219230597319307392C9F70A951D7`；
  publish build/deployed `Microsoft.Terminal.Control.dll` 均为 14,630,400 bytes，
  SHA-256 `FF2121CFFBA3EB1C7C0CAE6DF27E6B7F0459C47FC14D37A2CC62D48D9FC81E12`。
  Publish full WTA `1520/1520`，mixed build `218 warnings, 0 errors`，requested action
  tests包含在 `32/32` TAEF GREEN 中，packaged `CompletedTurnMouse` `2/2` GREEN，
  fresh C264 `[x]`。
- Hover visual evidence: 用户在 exact local Dev deployment 上手动确认 full-row target
  显示 hand cursor。跨应用 OS pointer scan 已删除：它曾错误移动到 VS Code 状态栏，
  不能作为产品证据；当前自动化只验证 action metadata、URI routing、stale cleanup 与
  underline suppression，不再移动真实鼠标。最终 hand-only 且无 underline 的视觉状态
  在 exact publish build 上保留人工验收。

For UI or terminal-rendering changes, screenshots are required evidence, not
optional decoration. Capture the failing state and the fixed state from the
real user workflow. Inspect and record that the target state is visible, output
is nonblank, layout is stable, and controls/text do not overlap or clip. Cover
all relevant pane positions, window sizes, themes, or interaction modes named
by 上述 User-Visible Contract。

### Review Triage

每轮 review 都追加一条记录，包含日期、review ID 或 head SHA、finding 路径与
摘要、accept/decline/escalate 决策、技术理由、RED 证据、处理方式、GREEN
验证和 publish commit。

Current review status: `PR #624；首轮 review 已完成 triage/fix，review-fix commit
已准备，等待新一轮 review`
Open review items: `11 个原始 threads 无法通过匿名 public API 回复或 resolve；fix push
后会变为 outdated，但 PR owner 仍需在 GitHub UI 中处理 thread 状态`

- `2026-08-17`, head `f44831d21999e8686c9b8f8a59eefdb1ab5a3a30`, Copilot review
  `4949789603`: accepted all 3 findings.
  - `renderer.cpp`, comment `3794888484`: accepted hot-path URI lookup/allocation
    concern. Added a per-frame `HyperlinkId` decision cache shared by render engines;
    cache/lookup failures continue to fall back to ordinary hyperlink decoration.
  - `action_links.rs`, comment `3794888526`: accepted duplicate steady-state repaint.
    Persistent geometry is no longer cleared before action repaint; removed/changed
    geometry still clears. Focused RED failed at `persistent geometry must not be drawn
    once to clear and again`; action overlay GREEN `4/4`.
  - `ui/chat.rs`, comment `3794888563`: accepted clipped-header correctness bug.
    Focused RED found visible `CLIPPED_PROMPT_ROW_5` without a hit target; prompt rows now
    clip independently from the triangle/header. Focused GREEN `1/1`.
- `2026-08-17`, Advanced Security spelling review `4949744870` and check run
  `95329000847`: accepted all 8 current alerts (15 annotations across repeated PR
  revisions), all the same `multiclick/MULTICLICK` token. Renamed prose/identifiers/
  markers to `multi-click`, `multi_click`, and `MULTI_CLICK`; no dictionary allowlist.
  The separate 54 dictionary-download 404 notices came from external cspell dictionary
  URLs and the workflow still concluded success; no repository config change warranted.
- No suppressed Copilot findings were present in the review body. Anonymous REST access
  can read all review/check data but cannot reply to or resolve threads; no login was
  attempted. Review-fix validation before package/E2E: WTA `1522/1522`, explicit-target
  build success, Control build `0 errors`, requested TAEF `3/3`. Publish review-fix
  commit `7cb94900132f8e3442cbe8e5d9da9d610b2f63da` passed full WTA `1522/1522`,
  mixed build `169 warnings, 0 errors`, host `3/3`, packaged E2E `2/2`, and fresh
  C264 `[x]`. Exact publish/deployed identities: `wta.exe` 32,461,312 bytes,
  SHA-256 `0268C9EBADCBD30519093713FE87DF8C3101D574A3A089C15D9D42CC71BC3635`;
  `Microsoft.Terminal.Control.dll` 14,638,080 bytes, SHA-256
  `E2A29A4FB84A9B2A594FD62DC3C29BE41CCA2CBE404EA4DFE5A4DA5D638C9BA5`.

### Local-Only Evidence

当前 evidence root：`test/e2e/artifacts/mouse-interactions/`。

- `red/before-click.png` 与 `red/after-click.png`：baseline 点击前后均保持展开。
- `green/before-click.png`、`green/after-click.png`、
  `green/after-reexpand.png`：最终 build 的展开、折叠、重新展开状态。
- `red/fixture.log` / `green/fixture.log`：各自唯一 prompt exactly once。
- `final/report.html`、`final/results.xml`、`final/summary.md`：最终 isolated
  Pester 1/1 GREEN；`final/release-report.md` 中 C264 为 `[x]`。
- `extension-red/before-prompt-click.png` / `after-prompt-click.png`：triangle-only
  baseline 点击第二条 prompt row 前后均保持展开。
- `extension-green/before-prompt-click.png`、`after-prompt-click.png`、
  `after-prompt-enter.png`：最终 Dev build 的展开多行、mouse-selected cyan collapsed
  summary、Enter 重新展开状态；相邻 `.txt` 是对应 pane captures。
- `extension-green/fixture.log`：deterministic prompts exactly once；
  `extension-green/release-report.md`：C264 `[x]`。最新 packaged result 为
  `test/e2e/artifacts/results.xml` / `summary.md`，`CompletedTurnMouse` 2/2 GREEN。

List ignored screenshots, pane captures, fixture logs, test reports, local E2E
frameworks, scripts, wire captures, and provider configurations. State which
artifact proves each user-visible assertion.

- Do not delete local E2E frameworks, scripts, wire captures, provider configs,
  screenshots, reports, or logs merely because they are ignored. Preserve them
  for reproduction, review follow-up, and extraction into a separate PR.
- If a screenshot or other evidence must be committed for review, copy the
  final selected artifact into the designated non-ignored
  `待 PR 创建时指定的 review-evidence 目录`. Do not force-add the ignored
  working artifact.
- If evidence does not need to be committed, keep it in its ignored location
  and record the exact path, command, package/binary identity, validation
  result, and visual conclusion in this handoff.

### Strict TDD workflow

1. Find and reuse the nearest existing test, fixture, helper, and E2E suite.
  Add the smallest focused/live case to that natural surface.
2. Build and deploy the exact baseline before RED so the binary is known.
3. Run only the new case and confirm it fails at the behavioral oracle for the
   expected reason. If it cannot reproduce, stop and report the evidence before
   changing product code.
4. Add the narrowest unit/state/render regression that captures the missing
  behavior and confirm RED.
5. Apply the smallest implementation at the owning abstraction.
6. Rerun the same focused and live/E2E checks for GREEN.
7. Run related tests, the full relevant suite, and required explicit builds.
8. Deploy the exact validated build using the narrowest supported flow, verify
  binary identity when applicable, and rerun the full related E2E suite.
9. Inspect visual evidence for nonblank output, expected state, stable layout,
  no overlap, and no clipping when UI behavior is involved. Record RED/GREEN
  screenshot paths and the inspection result.
10. Commit product/tests/existing-framework E2E/checklist metadata as the dev
  publishable commit. Keep large new local test frameworks modular and out of
  the feature commit; commit this handoff and local-only material separately.
11. Push dev and confirm remote synchronization, then directly cherry-pick the
  publishable commit into the publish worktree.

### Guardrails

- 保留 `▶` / `▼` 和 prompt text 点击行为，并把热区扩大到每条实际渲染 prompt
  row 的完整 chat content width；不得扩大到 reply/details、分隔行或其他 UI。
- 鼠标成功 click 必须复用现有 completed-turn keyboard selection 状态和样式；
  禁止新增平行的 mouse selection/highlight 状态。
- 必须区分 click 与 drag：任何 drag 都归文本选择，不得 toggle turn。
- Mouse Down/Up 必须命中同一 turn 的当前可见 triangle/user-input target；过期、
  滚出 viewport 或 resize 前的 hit region 必须安全 no-op。
- 多行、显式空行与自动换行 prompt 的 full-row hit region 必须来自实际 render
  geometry，不得按原始字符串长度猜测 row/column。
- Hand pointer 只允许出现在当前 full-row targets；必须处理 PointerExited 与 stale
  frame，不显示动作提示文字或 underline，且 custom action 不得成为可打开的 URI。
- 点击 input dialog 必须只复用 `clear_completed_turn_selection` 和现有 input focus
  语义，不得创建第二套 focus state 或提交空 prompt。
- 双击/三击文本选择的最终展开状态必须保持不变；不得用“每次 click 都 toggle，
  偶数次碰巧还原”代替明确的 multi-click 设计与测试。
- Do not infer user-visible behavior only from internal state; validate the
  actual output or workflow.
- Do not include unrelated fixes discovered during investigation. Record them
  under follow-ups and use a separate branch/PR.
- Do not delete ignored local E2E frameworks, scripts, wire/provider configs,
  screenshots, or logs. Preserve them and record their paths.
- Do not force-add ignored screenshots. Copy review-selected evidence into
  指定的非 ignored review-evidence 目录 when it must be committed.
- Format only touched files; avoid repository-wide mechanical churn.

### Optional Follow-Ups

- 本阶段只使用 hand pointer，不增加 hyperlink underline、tooltip、整行 hover 背景色、
  动画或 reply/details hover affordance；其他视觉扩展需另行评估可访问性与 redraw
  成本。

---

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
