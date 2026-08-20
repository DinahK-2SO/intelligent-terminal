# Markdown Rendering in Agent Pane Feature Handoff

> Last synchronized: 2026-08-20
>
> 这个文件只描述 Markdown Rendering in Agent Pane Feature。它应该可以直接复制到新的 dev branch，
> 让下一阶段不需要重新翻阅旧调查记录。实际代码始终是最终 source of truth。

当前 dev/publish branches:

- dev branch：`user/DinahK-2SO/markdown-renderer2`, remotely push to "Dinah".
- publish branch：`user/DinahK-2SO/markdown-renderer2-publish`, remotely push to "origin"；local
  worktree为`C:\ado\intelligent-terminal-markdown2-publish`。

当前dev branch从最新`origin/main@e870a3630`（`Wait for terminal window before COM probe
(#629)`）创建：

- dev HEAD为`52024f043 init`，其唯一parent是`e870a3630`；包含本handoff和dev-only
  `investigation-popular-agent-cli/`，没有上一代Markdown产品代码。
- dev已关联并push到`Dinah/user/DinahK-2SO/markdown-renderer2`。
- publish已直接从同一个`origin/main@e870a3630`创建并push/关联
  `origin/user/DinahK-2SO/markdown-renderer2-publish`；初始tree不含`AGENTS.md`变更、调查目录或
  其他dev-only tracking。

本branch是下一阶段正式implementation branch。每个TDD step的产品代码与正式tests先形成独立
product commit，再用单独dev-only commit更新本handoff；product commit同步到publish branch，
dev-only commit不进入publish。

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

## 当前follow-up

[2026-08-19] 新`markdown-renderer2`implementation branch已从clean latest main创建；正式TDD
implementation即将开始。Dev/publish branches均已创建、关联并push；clean-main explicit-target
WTA baseline为`1543 passed, 0 failed`。

Clean-main起点没有`tui-markdown`dependency、`agent_markdown_lines`或
`RenderAgentMarkdown`setting。上一代branch已经证明baseline Markdown behavior可行，但本branch
从RED重新实现，并直接向performance-first目标架构演进。新baseline已在
`origin/main@e870a3630`上完成；后续test count以本branch新增tests后的结果为准。

### `markdown-renderer2` implementation progress

#### Phase 1 Step 1：finalized canonical Markdown projection（完成）

- RED：新增`agent_message_renders_multiline_markdown_with_theme_relative_styles`；focused test
  `0 passed, 1 failed`，预期失败为`left: "● # Heading"`, `right: "● Heading"`。
- GREEN：新增`tui-markdown 0.3.9`（关闭default features）、pane-relative Markdown styles和
  `agent_markdown_lines`，finalized `ChatMessage::Agent`切到canonical projection。
- Focused GREEN：`1 passed, 0 failed`；`ui::chat::tests`为`38 passed, 0 failed`。
- Full WTA：`1544 passed, 0 failed`。
- Dependency compliance：`Generate-WtaThirdPartyNotices.ps1`成功，更新`Cargo.lock`、
  `cgmanifest.json`和`NOTICE.md`；touched Rust files已单独rustfmt。
- Product commit：`3a94a571d Render finalized agent responses as Markdown`。

#### Phase 1 Step 2：streaming canonical Markdown projection（完成）

- RED：新增`pending_stream_renders_markdown_and_preserves_partial_syntax`；focused test
  `0 passed, 1 failed`，预期失败为`left: "● # Heading"`, `right: "● Heading"`。
- GREEN：抽出deterministic `build_pending_stream_lines_for_tab`并把revealed prefix交给同一个
  `agent_markdown_lines`；raw source、reveal cadence和turn lifecycle不变。
- Partial syntax contract：未闭合`**bo`保留已显示`bo`且不panic；后续closure由同一renderer
  重新project。
- Focused GREEN：`1 passed, 0 failed`；chat module `39 passed, 0 failed`；full WTA
  `1545 passed, 0 failed`；`chat.rs`已单独rustfmt。
- Product commit：`283484ad9 Render streaming agent responses as Markdown`。

#### Phase 1 Step 3：default-on Settings model contract（完成）

- RED：新增`RenderAgentMarkdownRoundtripsAndDefaultsOn`；focused
  `UnitTests_SettingsModel` build按预期失败，`C2039: RenderAgentMarkdown is not a member of
  GlobalAppSettings`。
- GREEN：新增global setting `RenderAgentMarkdown` / JSON `renderAgentMarkdown`，default
  `true`，并投影到`GlobalAppSettings.idl`。
- Validation：focused project build成功（5 warnings、0 errors）；focused TAEF
  `1 passed, 0 failed`，覆盖显式`false`和missing-key default `true`。
- Product commit：`cd514fe17 Add Markdown rendering setting contract`。

#### Phase 1 Step 4：Settings > Agents Markdown toggle（完成）

- RED：新增现有desktop E2E framework test
  `Markdown rendering toggle defaults on and persists when disabled`；pre-implementation package中
  `RenderAgentMarkdownToggle`不存在，focused test为`0 passed, 1 failed`。
- GREEN：把`RenderAgentMarkdown`投影到`AIAgentsViewModel`，新增default-on two-way toggle、
  Header/HelpText/AutomationProperties.Name，并更新全部16个SettingsEditor locales；三个pseudo-locale
  使用精确English fallback。
- Build/deploy：focused `TerminalSettingsEditor` build为50 warnings、0 errors；Debug x64
  `CascadiaPackage` build为107 warnings、0 errors；loose Debug deployment成功。
- Focused GREEN：设置`ITE2E_PACKAGE=Dev`后为`1 passed, 0 failed, 0 skipped`；覆盖控件存在、默认on、
  关闭后保存`renderAgentMarkdown=false`。默认`Auto`会优先已安装Store package，不可用于验证本地
  Dev deployment。
- Resource validation：16个`.resw`均保持原line endings和UTF-8 BOM、XML可解析、三个新增key唯一且
  non-empty；PowerShell test parser为0 errors。
- Product commit：`fb9e4455e Add Markdown rendering setting UI`。

新的性能与产品设计记录在dev-only：

- `investigation-popular-agent-cli/popular-agent-cli.md`：Codex、goose、ForgeCode、Amazon Q、
  Warp和oh-my-pi的逐仓源码调查、二次采用审计及最终设计。
- `investigation-popular-agent-cli/assertions_result.txt`：早期结构化断言结果；实际源码和最终
  design note优先于该辅助文件。

### 当前最终decision

1. `tui-markdown -> WTA semantic styles -> Ratatui Line`仍是唯一canonical renderer；不引入
  JS runtime、termimad/bat direct stdout或第二套stream/final renderer。
2. 扩展或最小fork`tui-markdown`，使同一次pulldown-cmark pass返回rendered blocks、source
  ranges和`last_top_level_block_start`。不维护跨chunk Markdown parser state，也不复制
  CommonMark grammar。
3. Streaming采用Codex式`stable_source_len + final top-level block mutable`；reference
  definition/global rewrite回退current-response full recompute；completion对当前完整raw response
  做一次cold canonical render。
4. `PreparedChatLayout`一次prepare供height、viewport、selection和mouse hit-testing共同使用；
  retained history按stable item identity缓存，只materialize visible + overscan items。
5. Stream输入采用append lineage、约33ms上限coalescing、structure-event ordering barrier和
  grapheme-safe reveal/wrap；cache必须有entry/total/per-entry三重上限。
6. **下一阶段目标**：Settings model和Settings > Agents toggle `RenderAgentMarkdown` / JSON
  `renderAgentMarkdown`已完成且默认`true`。当前源码尚无helper bootstrap flag或live event field；
  实现后关闭时绕过Markdown parser/cache并显示raw markers，通过helper bootstrap flag和
  `agent_config_changed`live update原地切换，不restart agent/helper/session。
7. Table执行natural/preferred widths -> bounded shrink -> stacked fallback；code highlighting是
  独立、bounded、pane-theme-aware、versioned的后续层。

这是明确的目标架构，不再把“每个visible frame完整parse当前response prefix”视为最终可接受
方案。Phase 0/1/2可以拆成多个TDD commit/PR以控制风险，但Phase 2 source-prefix cache属于目标，
不是可选research。

### 上一代Baseline实现与历史调查

下面Step 1-5记录上一代`user/DinahK-2SO/markdown-renderer`branch已经完成的baseline TDD与
OpenCode技术调查。它们是历史evidence，不代表当前`markdown-renderer2`源码已经实现；若与上面的
2026-08-19 decision冲突，以上面decision和当前源码为准。

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

该baseline decision仍有效。新的性能设计只扩展projection API和helper-side cache/layout
ownership，不更换Markdown semantics，也不把parser移到C++、ACP master或history model。

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
  上一代`Dinah/user/DinahK-2SO/markdown-renderer`并确认同步。

Step 2让streaming pending buffer复用同一个renderer：

- RED：新增`pending_stream_renders_markdown_and_preserves_partial_syntax`；第一次修正test fixture
  后，同一focused command失败为`left: "● # Heading"`, `right: "● Heading"`。
- GREEN：`cargo test --manifest-path tools/wta/Cargo.toml pending_stream_renders_markdown_and_preserves_partial_syntax -- --nocapture`
  为`1 passed, 0 failed`；chat module为`33 passed, 0 failed`。
- Streaming contract：typewriter仍先用`reveal_chars`切出当前可见buffer，再对整个可见buffer重新
  parse/project。未闭合的`**bo`必须保留已显示的`bo`并且不能panic；finalize仍把完整raw buffer
  存入`ChatMessage::Agent`，不保存parser state。
- Commit/push：`90b2f992c Render streaming agent responses as Markdown`。

Step 3覆盖GFM table和布局高度：

- RED：新增`narrow_table_preserves_rows_and_matches_finalized_and_pending_heights`；修正test width
  类型后，focused command失败为actual pending `14`行、estimated `10`行。
- GREEN：pending renderer和height estimator共享`pending_revealed_text`，并都通过
  `agent_markdown_lines`投影；同一focused command为`1 passed, 0 failed`。
- Table contract：24-column窄viewport中的3-column grid保留A/B/C三条box-grid data row；finalized、
  full pending和partial typewriter reveal的actual lines都必须等于各自height calculation。
- Commit/push：`7d7a80d6a Keep Markdown table heights consistent`。

Step 4固定agent pane light/dark theme contract：

- Source check：C++ `AgentPaneContent`/`TerminalPage`拥有agent pane实际foreground/background；Rust
  renderer不读取普通terminal profile theme，也不复制light/dark palette。
- `tui-markdown`默认H1会设置cyan background、code会设置white-on-black；WTA Step 1的
  `AgentMarkdownStyleSheet`已经覆盖这两项。
- 新增`agent_markdown_styles_follow_the_agent_pane_palette`作为characterization/regression test；
  它直接GREEN，因此本step没有额外产品behavior change。测试确认正文/heading/code/quote/meta/table
  使用`Color::Reset`基色且无background，link仅使用agent pane ANSI cyan，完整Markdown corpus没有
  span设置显式background。
- Commit/push：`e62a4d88a Test agent Markdown theme relativity`。

Step 5补充调查OpenCode技术栈的两条替代路线；本step不改变behavior，因此没有RED/GREEN：

#### 方向1：Rust能否直接加载OpenCode使用的JavaScript包

需要区分`marked` parser和OpenTUI `MarkdownRenderable` renderer：

- **只嵌入`marked`：技术上可行。** `marked`发布browser/ESM/UMD bundle；它的核心lexer可在
  browser中运行，不依赖Node filesystem/process API。Rust可把固定版本的`marked.umd.js`作为
  build artifact嵌入binary，初始化一个JS context，调用`marked.lexer(markdown, { gfm: true })`，
  再把token tree通过JSON或typed bridge传回Rust。
- 可选JS engine包括：
  - `boa_engine 0.21.1`：pure Rust、支持embedded/custom module loader，最符合single Rust binary；
    但项目仍把自己描述为experimental且不是Node/npm runtime，需要先验证当前`marked` bundle用到的
    ECMAScript语义。
  - `rquickjs 0.12.2`：QuickJS-NG binding，启动轻、支持module loader和embedded bytecode；但它会
    编译C library，runtime有thread lock。Windows x64 MSVC有预生成binding，其他WTA Windows targets
    尤其ARM64需要bindgen/toolchain/static-CRT验证。
  - `deno_core`/`v8`：兼容性最高，但引入V8、单独event loop和显著build/package成本；`JsRuntime`
    是`!Send + !Sync`，对于只做Markdown tokenization明显过重。
- **“有JS engine”不等于“可以npm install”。** Boa/QuickJS/`deno_core`本身不是Node/Bun package
  manager；必须在build时锁定并bundle `marked`，或自行实现module resolver。依赖外部Node/Bun
  subprocess则要求用户机器安装对应runtime，不能作为packaged WTA产品contract。
- 即使成功运行`marked`，仍必须在Rust中维护`MarkedToken -> Ratatui Line/Span`、table layout、
  styled wrapping、agent prefix和height estimation。也就是说它只替换当前`pulldown-cmark` parser，
  不会得到OpenCode的实际显示效果。
- 还会新增JS engine生命周期、panic/exception和memory limit、JS/Rust token schema、每次typewriter
  reveal的cross-runtime调用、bundle更新和第三方notice等ownership。除非发现一个必须逐字匹配
  `marked`的compatibility bug，这些成本没有对应产品收益。

- **嵌入完整`@opentui/core`/`MarkdownRenderable`：不能只靠通用JS engine完成。**
  `MarkdownRenderable`依赖`RenderContext`、`CodeRenderable`、`TextTableRenderable`、`BoxRenderable`、
  `StyledText`和OpenTUI buffer；OpenTUI本身是Zig native core + TypeScript binding，通过FFI使用Yoga、
  terminal renderer和native text buffers，还带Tree-sitter worker/WASM/query assets。创建native renderer
  通常需要Bun，或Node 26.4 experimental FFI及platform-specific native package。
- OpenTUI native core虽然暴露C ABI，Rust理论上可以直接binding，但Markdown token到renderable的逻辑
  仍在TypeScript层。为了只取得几行文本而引入第二套layout/terminal renderer，再把offscreen buffer
  转回Ratatui，会同时存在OpenTUI和Ratatui两套terminal、layout、theme和scroll ownership；这比移植
  renderer更复杂，也容易与当前Crossterm/Ratatui lifecycle冲突。

方向1结论：**可以在Rust里跑`marked`，但不能低成本复用OpenCode的renderer。** 若未来必须验证
`marked` parity，最小prototype应为`Boa/QuickJS + vendored marked UMD -> JSON tokens`，且只能作为
parser A/B test，不应直接接管WTA rendering。

#### 方向2：OpenCode依赖是否有对应Rust版本

没有一比一的`marked-rs`或`MarkdownRenderable-rs`，但每层都有Rust-native counterpart：

| OpenCode层 | Rust候选 | 结论 |
|---|---|---|
| `marked` GFM lexer/token tree | `pulldown-cmark`、`comrak`、`markdown-rs`、`markdown-it` | 无`marked`官方移植。`pulldown-cmark`是低分配event stream；`comrak`提供完整GFM AST；`markdown-rs`提供mdast/GFM；`markdown-it`是`markdown-it.js`移植，不是`marked`移植。 |
| OpenTUI `MarkdownRenderable` | `tui-markdown` | 最接近当前ownership：直接生成Ratatui `Text`，已有GFM table、wide character width和`StyleSheet`。当前实现已经采用。 |
| OpenTUI table/layout | `tui-markdown` table builder、Ratatui | 能生成box grid，但OpenTUI的Yoga/component reconciliation没有对应的drop-in Rust port；WTA继续拥有prefix、wrapping和height。 |
| OpenTUI Tree-sitter Markdown highlighting | `tree-sitter` + `tree-sitter-md 0.5.3` + `tree-sitter-highlight` | Rust binding和同源split `markdown`/`markdown_inline` grammar都存在。grammar自身明确不建议作为correctness parser，适合作为highlight/conceal层。 |
| fenced-code highlighting | `syntect` + `ansi-to-tui`，或上述Tree-sitter stack | `tui-markdown`默认feature已经提供Syntect路径；当前关闭它是为了避免默认固定dark theme。精确复刻OpenCode则要维护language grammar/query/injection registry、theme-group映射、streaming cache和assets。 |
| 完整terminal renderer | Ratatui | WTA已经基于Ratatui；替换为OpenTUI不是Markdown dependency change，而是整个helper UI framework migration。 |

Rust parser进一步取舍：

- `comrak 0.54.0`最适合需要GitHub-compatible AST和高度可配置extensions的场景，但它不输出Ratatui，
  仍需自建terminal renderer；AST/arena也比当前event projection更重。
- `markdown-rs 1.0.0`提供100% CommonMark/GFM和位置完整的mdast，适合复杂transform，不提供terminal
  renderer。
- `markdown-it 0.6.1`具有JS `markdown-it`式plugin/AST模型，适合自定义syntax，但不是OpenCode所用
  `marked`的token contract，且仍没有Ratatui adapter。
- `tree-sitter-md`与OpenTUI使用的grammar同源并支持GFM table/task list/strikethrough，但其README明确
  说明Markdown受Tree-sitter grammar限制、存在不准确项，目标是syntax highlighting而非规范解析。

方向2结论：**Rust已有功能等价组件，但没有OpenCode整栈的drop-in port。** 当前
`pulldown-cmark (via tui-markdown) -> Ratatui -> WTA layout/theme`是最小且ownership正确的组合。
未来若增加code highlighting，应在独立step比较：

1. 启用`tui-markdown`的Syntect feature，并解决agent pane light/dark code theme选择；或
2. 增加Rust Tree-sitter highlight layer，复用`tree-sitter-md`及各language query。

两者都不应把Tree-sitter替换成Markdown correctness parser，也不应为了parser parity引入完整JS/OpenTUI
runtime。只有出现经fixture证明的`pulldown-cmark`与agent输出不兼容时，才重新评估`marked` embedding
或`comrak`/`markdown-rs` AST路线。

### Build和live evidence

- `cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml`成功。
- full `bcz no_clean`被本机缺少.NET 8 targeting/reference packs阻塞：14个`NU1102`来自
  `TerminalStress`、`WpfTerminalControl`和`WpfTerminalTestNetCore`；用户拒绝了system-wide .NET 8
  SDK安装。改用产品范围`cd src/cascadia/CascadiaPackage && bx`成功：107 warnings、0 errors。
- `Invoke-IntelligentTerminalDebugDeployment.ps1`成功部署
  `IntelligentTerminal_0.8.0.2_x64__rd9vj3e6a2mbr` loose Debug layout。
- 现有`Feature.AgentPaneInteraction.Tests.ps1`为13 passed、1 failed：window/pane toggle、stash、input、
  streaming和真实Copilot chat通过；唯一失败是`/model` popup的PowerShell capture mojibake导致Unicode
  border regex不匹配，与Markdown renderer无关。
- Live Markdown验证固定active tab对应的helper，避免多helper harness选错pane。真实Copilot response中的
  response-only products `49/56/63/64/72/81`与bold result可见，raw heading/bold/table markers均不可见。
- Dark evidence目视确认3x3 grid和bold result完整、无重叠。独立light evidence保持普通shell深色，
  只把hidden Agent Pane profile覆盖为`One Half Light`；agent surface变浅，heading/table/bold都可读，
  证明`Color::Reset`跟随agent pane自己的scheme而非普通terminal/app theme。
- Local screenshots保留在ignored `test/e2e/artifacts/markdown-renderer/`，未加入feature commit；其中包含
  local paths，分享或复制到review evidence前必须清理。
- 上一代baseline publish feature commit为`31b96784b Render agent responses as Markdown`；merge
  main后的local publish HEAD为`b0ceb8856`。相对`origin/main@08957118a`的review diff只包含
  六个产品文件，不含本handoff、调查目录或local artifacts；publish worktree full WTA tests为
  `1547 passed, 0 failed`。
- 上一代dev local HEAD为`969b98cbd`，其产品blob与publish一致；dev额外包含调查/tracking。

下一阶段允许扩展`tui-markdown`的streaming projection API以暴露pulldown-cmark block offsets；
这不等于扩展Markdown syntax或引入第二个parser。Publish只带产品代码、正式tests、localization和
必要third-party metadata，不带本handoff、`investigation-popular-agent-cli/`或本地E2E artifacts。


========================

## 在开始下一阶段正式开发前

下一阶段会改变Settings UI、helper bootstrap/runtime config、stream scheduling和chat layout；开始
正式开发前先确认这些live acceptance仍然可以完成：

1. build/deploy existing Intelligent Terminal并launch；
2. 截图并确认Terminal窗口visible且nonblank；
3. 点击Bottom Bar按钮展开agent窗口，截图并确认agent对话UI可见；
4. 默认选择的provider是copilot，截图并确认active agent确实active；
5. 与copilot对话要求multiple paragraphs、bold、unclosed-then-closed syntax和3x3 table，等待
  response后确认stream与final显示完整、无重叠；
6. 在Settings > Agents关闭Markdown toggle，确认raw `#`、`**`、fence和table pipes可见，且
  helper/session identity不变；重新开启后rich rendering恢复、history不丢失；
7. 分别在dark/light agent pane、narrow/wide pane和stashed/prewarmed helper验证相同contract。

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
branch先follow existing ownership；大型架构refactoring留到独立branch。Markdown toggle复用
Settings model/ViewModel/XAML pattern和`AgentRuntimeConfigSnapshot -> agent_config_changed`热更新
route；不要创建平行settings/event route，也不要把presentation setting放进master identity。

关于tests是否commit：现有framework能自然cover的tests应该commit；新的本地桌面E2E framework
只保留本地，未来另开framework PR。

========================

## 最终产品设计

### 用户看到什么

- 默认开启时，agent response以正确的Markdown semantics显示；stream与final结果一致。
- 用户可在Settings > Agents关闭Markdown rendering，立即查看raw Markdown markers；切换不重启
  agent/helper/session，也不改变raw history。
- 长stream、长history、Unicode、table、resize、scroll、selection和mouse interaction保持响应。

========================

## Feature内部数据流与ownership

### 当前baseline（已实现）

```text
ACP message events
  -> TabSession::append_agent_chunk()
  -> TabSession.messages / ChatMessage::Agent(String)
  -> TabSession::streaming_agent_text()
  -> ui::chat finalized/pending agent_markdown_lines
  -> Ratatui Paragraph
```

### 目标数据流（尚未实现）

```text
ACP AgentMessageChunk
  -> ordered/coalesced helper events
  -> TabSession raw ChatMessage::Agent + source_revision/source_generation
  -> grapheme-safe visible cursor
  -> enabled: tui-markdown/pulldown-cmark single pass
       -> rendered top-level blocks + source ranges
       -> stable_source_len + mutable final block
     disabled: raw plain-text projection（parser/cache bypass）
  -> WTA semantic styles + styled-grapheme wrapping
  -> bounded per-item semantic/layout cache
  -> PreparedChatLayout（height + visible/overscan rows + selection/mouse geometry）
  -> Ratatui Paragraph / retained viewport
  -> agent pane TermControl using its own color scheme

completion
  -> cold canonical render of current raw response
  -> finalized per-item cache
```

`ui/chat.rs`及后续拆出的Markdown/cache modules必须让height、display、selection和mouse hit-testing
消费同一个`PreparedChatLayout`。ACP/master、ChatMessage storage和C++ pane不保存parsed Markdown
AST、ANSI或Ratatui lines，也不做provider-specific Markdown transformation。唯一authoritative
source boundary来自pulldown-cmark top-level offset events；其他scanner只能让cache更保守，不能
自行推进`stable_source_len`。


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

- finalized message和streaming message使用不同Markdown semantics；两者必须调用同一个canonical
  renderer，completion cold render必须能验证incremental结果。
- 使用固定dark syntax theme或hardcoded white foreground，导致light agent pane不可读。
- height estimator继续数raw Markdown characters而actual renderer已经隐藏syntax marker。
- 每个frame遍历/重parse整个conversation，或height/render分别构建同一projection。
- 用blank-line scanner、line LCP或第二套parser自行推进`stable_source_len`。
- Toggle切换时restart agent/helper/session，或让disabled mode仍调用Markdown parser/cache。
- Cache无entry/byte上限、async highlight无source/theme version token、wrap拆开grapheme。


========================

## Definition of Done for next follow-up

一个follow-up step完成必须满足：

- behavior符合本contract或明确记录的新decision；
- 有focused RED/GREEN evidence；
- relevant full tests/build通过；
- incremental streaming在每个growth point与cold canonical render的text/style/height一致；
- benchmarks/counters证明每frame不遍历完整conversation，normal append只处理dirty item和pending
  suffix，cache memory有界；
- random chunk、UTF-8/grapheme、reference、CRLF、source replacement、table、code和无尾随newline
  fixtures通过；
- Settings toggle完成model round-trip、全locale/pseudo-locale、accessibility、bootstrap/live update和
  existing/stashed/new helper E2E；切换前后session identity/raw history不变；
- logs/telemetry不包含Usage、raw prompts或Markdown source；
- local E2E evidence保留且敏感/ignored artifacts不误commit；
- dev/publish scope正确；
- commit已push且branch同步；
- 本handoff更新完成，下一branch无需重新调查。


以下是project-wide 的一些background knowledge。仅供参考，请以实际代码实现为准。

=================================================

# Intelligent Terminal

Intelligent Terminal is a Windows Terminal fork that adds first-class AI agent
workflows. The inherited Windows Terminal build, architecture, and C++ conventions
are documented in `.github/copilot-instructions.md`; this file contains only the
fork-specific context.

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
    "showTokenUsageAndCost": false,
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
- `hook-trace.log`

Use `WTA_LOG=debug` or `WTA_LOG=trace` for additional Rust tracing. See
`tools/wta/README.md` for current diagnostics and CLI usage.

## Focused design references

- Multi-window helper/master lifecycle:
  `doc/specs/Multi-window-agent-pane.md`
- Session tracking: `doc/specs/hybrid-agent-session-tracking.md`
- Security boundaries: `doc/security-model.md`
- Installer: `doc/building-installer.md`
- WTA customization: `tools/wta/CUSTOMIZATION.md`
