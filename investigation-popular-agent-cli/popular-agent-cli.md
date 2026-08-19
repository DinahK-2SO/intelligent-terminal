# Windows AI Agent CLI 竞品调查

> 调查日期：2026-08-18
>
> 范围：可在 Windows 原生环境、WSL 或 Docker Desktop 中运行，且能自主读取/修改
> 代码、执行命令或完成多步骤软件工程任务的 terminal-first agent。纯聊天 CLI、纯 IDE
> 插件、agent SDK 和多 agent 管理器不列入主榜。

## 排序口径

这不是权威下载榜。闭源产品通常不公开安装量，因此采用综合热度排序：

- 社区/采用信号：GitHub stars、厂商品牌、公开生态和用户覆盖。
- 当前动量：2026 年仍活跃、近期发布/提交、新产品增长速度。
- Agent 完整度：文件编辑、shell、测试闭环、交互与 headless 自动化。
- Windows 成熟度：原生安装优先，其次 WSL/Docker；再看 ACP/MCP 和企业能力。

GitHub stars 为 2026-08-18 快照，四舍五入到 0.1k。闭源产品标记为 N/A，不能直接与
开源 stars 比较。

Windows 路径说明：

- **Native**：官方 Windows binary、PowerShell、WinGet、Scoop、Chocolatey、npm 或
	Python 安装后可直接运行。
- **WSL**：官方推荐或实际需要 Linux 用户态。
- **Docker**：主要通过 Docker Desktop/容器运行。

## Top 20

| # | Agent CLI | 热度信号 | Windows 路径 | 开放性 | 协议/扩展 | 核心定位 |
|---:|---|---:|---|---|---|---|
| 1 | [Claude Code](https://github.com/anthropics/claude-code) | 141.8k；Anthropic 主力产品 | **Native**：PowerShell installer / WinGet | 商业产品；公开仓库无 OSI license | MCP、hooks、plugins；ACP 需 adapter | 高完成度 coding agent，强代码库理解、git 与长任务执行 |
| 2 | [OpenCode](https://github.com/anomalyco/opencode) | 198.6k；开源榜首 | **Native**：npm / Scoop / Chocolatey | MIT | 原生 ACP、MCP、多 provider | 开源多模型 agent，TUI、desktop、plan/build agent 与 subagent |
| 3 | [OpenAI Codex CLI](https://github.com/openai/codex) | 106.5k；OpenAI/ChatGPT 分发 | **Native**：PowerShell installer / npm | Apache-2.0 | MCP；ACP 需 adapter | 轻量本地 coding agent，ChatGPT 登录、sandbox 和自动化模式 |
| 4 | [Gemini CLI](https://github.com/google-gemini/gemini-cli) | 106.5k；Google 免费层 | **Native**：npm / npx | Apache-2.0 | 原生 ACP、MCP、extensions | 1M context、Search grounding、多模态、headless/stream JSON |
| 5 | [GitHub Copilot CLI](https://github.com/github/copilot-cli) | 11.1k；GitHub/Copilot 用户基盘 | **Native**：WinGet / npm | 商业产品；非标准开源许可 | 原生 ACP、MCP、LSP | GitHub issue/PR 深度集成，多模型，企业策略与订阅分发优势 |
| 6 | [Cursor CLI](https://cursor.com/docs/cli/overview) | N/A；Cursor IDE 用户基盘 | **Native**：PowerShell installer | 闭源商业产品 | MCP；未见公开 ACP server | 与 Cursor editor/cloud agent 联动，Agent/Plan/Ask 和 print mode |
| 7 | [Cline CLI](https://github.com/cline/cline) | 66.4k；从 IDE 扩展到 CLI/SDK | **Native**：`npm i -g cline` | Apache-2.0 | 原生 ACP、MCP、SDK/plugins | 多 provider/local model、headless JSON、teams、schedule、消息平台连接 |
| 8 | [goose](https://github.com/aaif-goose/goose) | 52.9k；Linux Foundation AAIF | **Native**：官方 Windows app/binary | Apache-2.0 | ACP provider、MCP（70+ extensions） | 不只 coding：研究、数据、自动化；15+ provider，CLI/desktop/API |
| 9 | [OpenHands Agent Canvas](https://github.com/OpenHands/OpenHands) | 84.4k | **Docker/Native**：Docker Desktop 或 npm+uv | MIT | ACP client/orchestrator、automations | 自托管多 agent 控制面，可运行 OpenHands/Claude/Codex/Gemini |
| 10 | [Aider](https://github.com/Aider-AI/aider) | 48.3k；6.8M PyPI installs（项目 badge） | **Native**：Python installer | Apache-2.0 | 多 provider；无公开 ACP | 精准 git-centric pair programming、repo map、lint/test 自动修复 |
| 11 | [Qwen Code](https://github.com/QwenLM/qwen-code) | 27.1k；Alibaba/Qwen 生态 | **Native**：PowerShell installer / npm | Apache-2.0 | ACP daemon（experimental）、MCP、SDK | 开源多协议、多 provider、subagents/teams、desktop 与 IM bots |
| 12 | [Kiro CLI](https://kiro.dev/docs/cli/) | N/A；AWS/Kiro 分发 | **Native**：MSI / PowerShell installer | 商业产品 | 原生 ACP、MCP、hooks、skills | spec/steering 工作流、headless、voice、subagents、企业能力 |
| 13 | [Amp CLI](https://ampcode.com/manual) | N/A；Sourcegraph 团队/付费产品 | **WSL**（官方 Windows 支持口径） | 闭源商业产品 | MCP、skills、plugins、subagents | 多模型 frontier agent、Oracle/Librarian、remote threads/orbs、团队协作 |
| 14 | [DeepSeek-Reasonix](https://github.com/esengine/DeepSeek-Reasonix) | 34.7k；2026 快速增长 | **Native**：npm prebuilt binary / Windows archive | MIT | 原生 ACP、MCP/plugins | 单 Go binary、cache-stable long run、planner+executor、checkpoints |
| 15 | [Crush](https://github.com/charmbracelet/crush) | 27.5k；Charm 生态 | **Native**：WinGet / Scoop / npm | FSL-1.1-MIT | MCP、skills、LSP、hooks | 优秀 TUI、多模型/本地模型、跨平台内置 shell 与 workspace server |
| 16 | [oh-my-pi (`omp`)](https://github.com/can1357/oh-my-pi) | 25.5k；2026 快速增长 | **Native**：PowerShell installer；无需 WSL | MIT | 原生 ACP、MCP、RPC、SDK | 31 built-in tools、LSP/DAP、subagents、desktop/browser control、多 provider |
| 17 | [Kimi Code CLI](https://github.com/MoonshotAI/kimi-code) | 6.9k；2026 新仓库，接替 Kimi CLI | **Native**：PowerShell installer；需 Git for Windows | MIT | 原生 ACP、MCP、plugins/hooks | 单 binary 快启动、视频输入、parallel subagents、Kimi OAuth/API |
| 18 | [Mistral Vibe](https://github.com/mistralai/mistral-vibe) | 4.8k；Mistral 官方 | **Native**：uv/pip；官方仍以 UNIX 为主要目标 | Apache-2.0 | 原生 ACP、MCP、skills/hooks | 轻量多 agent profile、subagents、programmatic JSON、原生 PowerShell fallback |
| 19 | [Trae Agent](https://github.com/bytedance/trae-agent) | 12.0k；ByteDance research | **WSL/Docker 推荐**：uv source install | MIT | MCP、多 provider | 研究友好、trajectory 完整记录、test-time scaling 与透明 agent 架构 |
| 20 | [mini-SWE-agent](https://github.com/SWE-agent/mini-SWE-agent) | 6.6k；官方接替 SWE-agent | **WSL/Docker 推荐**：uvx/pip，核心依赖 bash | MIT | LiteLLM/OpenRouter；无公开 ACP | 极简约 100 行 agent、SWE-bench/研究/批处理、容器部署友好 |

## Windows 兼容分层

### 原生 Windows 第一梯队

安装与日常使用阻力最低：

- Claude Code、Codex CLI、GitHub Copilot CLI、OpenCode。
- Gemini CLI、Cursor CLI、Cline CLI、Kiro CLI。
- Qwen Code、Crush、Reasonix、oh-my-pi、Kimi Code CLI。

其中 `omp` 明确以“Windows 无 WSL bridge”为卖点；Crush 内置跨平台 shell；Kimi Code
依赖 Git for Windows 的 Git Bash；Mistral Vibe 可原生运行，但官方仍主要面向 UNIX。

### WSL / Docker 更稳妥

- Amp 官方支持口径是 Windows via WSL。
- Trae Agent、mini-SWE-agent 都以 bash/Unix 工作流为主，WSL 或 Docker 更可靠。
- OpenHands 在 Windows 上最成熟的隔离路径是 Docker Desktop；无 sandbox 直跑权限很高。

## Intelligent Terminal 竞品含义

### 下一批最值得接入

按协议成熟度、Windows需求和市场热度，建议优先级：

1. **Cline CLI**：原生 ACP，CLI/headless/JSON 完整，用户量大且多 provider。
2. **Kiro CLI**：原生 Windows + ACP，AWS 企业用户和 spec/steering 差异明显。
3. **Qwen Code**：Windows 原生、ACP daemon、中文/亚洲市场、多 provider。
4. **Kimi Code CLI**：原生 ACP、Windows installer，产品处于快速上升期。
5. **Reasonix 或 Mistral Vibe**：二者均原生 ACP；前者社区增长快，后者有模型厂商品牌。

已有内置支持的 Copilot、Claude、Codex、Gemini、OpenCode 仍覆盖当前最核心市场。Claude
和 Codex 本体不直接提供 ACP server，现有 adapter 路线仍有版本兼容和 npm supply-chain
成本；应持续优先推动native ACP或vendor-supported bridge。

### 产品趋势

- **ACP 正从差异点变成门槛**：OpenCode、Gemini、Copilot、Cline、Kiro、Reasonix、
	Kimi Code、Mistral Vibe、omp 均已提供或公开强调 ACP 路径。
- **Headless/structured output 是企业入口**：JSON/stream JSON、CI、remote runner、schedule
	已成为头部CLI标配。
- **多 agent 与隔离 worktree 普及**：Cline、Amp、Qwen、Kiro、omp 已把subagent/parallel
	execution放进主产品，而不是外部脚本。
- **Windows native体验仍有空位**：不少强agent依赖WSL、Git Bash或Docker；Intelligent
	Terminal可通过package identity、ConPTY、PowerShell与可视化权限/状态建立优势。
- **权限和信任边界更重要**：多数CLI可自动运行shell、加载项目内MCP/skills/hooks；产品
	必须清楚展示provider、工具权限、工作目录、sandbox和外部数据流。

## 未进入主榜但值得跟踪

- [Continue](https://github.com/continuedev/continue)：35.5k，但仓库已明确只读并完成最终
	2.0 release，不再是活跃竞品。
- [SWE-agent](https://github.com/SWE-agent/SWE-agent)：20.1k，但官方建议新用户改用
	mini-SWE-agent。
- [Kimi CLI](https://github.com/MoonshotAI/kimi-cli)：11.2k，正在被 Kimi Code CLI 接替。
- [GPT Engineer](https://github.com/AntonOsika/gpt-engineer)：55.1k，但已归档。
- [GPT Pilot](https://github.com/Pythagora-io/gpt-pilot)：33.7k，仍有知名度，但当前CLI动量
	弱于主榜中的新一代terminal agents。
- [Amazon Q Developer CLI](https://github.com/aws/amazon-q-developer-cli)：约2.0k；开源版已
	停止积极维护，只接收关键安全修复，官方安装仅列macOS/Linux；后继Kiro CLI为闭源产品。
- [ForgeCode](https://github.com/tailcallhq/forgecode)、[Freebuff](https://github.com/CodebuffAI/freebuff)、
	[gptme](https://github.com/gptme/gptme)：活跃且有差异化，适合后续长尾provider调查。

## 数据来源

- GitHub REST repository metadata：stars、license、archived、`pushed_at`，抓取于
	2026-08-18。
- 各产品官方README/文档：安装方式、Windows支持、agent/headless能力、ACP/MCP。
- Intelligent Terminal现有agent registry：Copilot、Claude、Codex、Gemini、OpenCode
	的当前集成方式和ACP adapter边界。

Stars变化很快；后续用于产品决策时，应重新抓取数据，并补充Windows实机安装、登录、
首个真实turn、session resume、ACP handshake和卸载残留测试。

## Rust 技术栈专项

以下项目的Rust采用情况经过GitHub Linguist语言字节数、当前源码树和Cargo workspace
交叉验证。字节数是仓库快照中的语言占比证据，不等同于代码行数、可执行文件大小或产品
成熟度；是否支持Windows则以官方文档或release artifact为准。

| 项目 | Rust角色/架构 | GitHub语言证据 | Windows路径 | 开放性 | ACP / MCP | 成熟度与WTA相关性 |
|---|---|---:|---|---|---|---|
| [OpenAI Codex CLI](https://github.com/openai/codex) | **完整Rust agent核心**；大型多crate workspace，覆盖TUI、agent loop、sandbox、app server与协议层 | Rust约50.0 MB | **Native x64/ARM64**：官方`.exe`、PowerShell installer及npm平台包 | Apache-2.0 | MCP client/server；无原生ACP server，WTA需adapter | **头部成熟**；与WTA同为Rust TUI/本地编排路线，是Windows sandbox、终端渲染和长会话设计的首要参考 |
| [goose](https://github.com/aaif-goose/goose) | **完整Rust agent核心**；核心agent、CLI、provider、extension与ACP服务均在Rust workspace | Rust约8.7 MB | **Native x64**：官方CLI及Windows app ZIP；另有CUDA包 | Apache-2.0 | 原生ACP provider/server能力、MCP | **头部成熟**；协议化、多provider和扩展生态最接近WTA希望承载的通用agent能力 |
| [ForgeCode](https://github.com/tailcallhq/forgecode) | **完整Rust CLI/TUI核心**；多crate workspace，内含agent、provider、工具、会话和语义搜索模块 | Rust约4.65 MB；7.5k stars | **Native x64/ARM64**：官方MSVC `.exe` | Apache-2.0 | MCP；未见公开ACP server | **活跃成长期**；单binary、多provider、skills/agents及Windows交付对WTA有直接参考价值 |
| [Amazon Q Developer CLI](https://github.com/aws/amazon-q-developer-cli) | **完整Rust CLI核心**；`chat_cli`及相关功能由多crate workspace实现 | Rust约11.5 MB | 官方开源版只列macOS/Linux；Windows宜用WSL，且无Windows release asset | MIT OR Apache-2.0 | MCP；未见公开ACP server | **历史成熟、现已退役**；只接收关键安全修复并迁移到闭源Kiro，不应作为新接入优先项，但可研究Rust shell integration架构 |
| [Warp](https://github.com/warpdotdev/warp) | **Rust终端/agent开发环境**，不是单一headless agent CLI；当前workspace包含terminal、`ai`、`mcp`、`computer_use`、`warp_cli`等模块 | Rust约63.1 MB；64.3k stars | **Native x64/ARM64**：官方Windows产品；官方构建优先 | client为AGPL-3.0；云端/商业服务另计 | MCP；未见公开ACP server | **头部终端产品**；与Intelligent Terminal在“terminal原生agent体验”上直接竞争，适合比较渲染、上下文采集和GUI/TUI融合 |
| [oh-my-pi (`omp`)](https://github.com/can1357/oh-my-pi) | **TypeScript + Rust混合栈**；agent/TUI/SDK主体是TypeScript，Rust承担native性能层，不能归为纯Rust项目 | TypeScript约50.1 MB；Rust约5.21 MB | **Native**：官方PowerShell installer，无需WSL | MIT | 原生ACP、MCP、RPC | **高动量成熟项目**；其native core边界、Windows直跑和ACP接口比“语言纯度”更值得WTA参考 |
| [Claw Code](https://github.com/vikrant-project/claw-code) | **自称完整Rust实现**；7个crate覆盖core、provider、tools、CLI、config、MCP和sandbox | Rust仅约44 KB；3 stars | README提供PowerShell installer和Cargo安装，但**无GitHub Release**可验证二进制 | MIT | README宣称MCP；未见ACP | **实验性/低证据**；仓库体量、采用量和发布链均远低于上述项目，不能与Codex/goose并列作成熟竞品 |

### 分层结论

1. **成熟全Rust agent**：Codex和goose是最强基准；ForgeCode规模较小但活跃且Windows
	发行完整。三者都证明Rust足以承载agent loop、TUI、协议、工具执行和跨平台交付。
2. **历史全Rust实现**：Amazon Q开源版有真实的大型Rust架构，但产品方向已转到闭源
	Kiro，适合读代码，不适合继续按活跃竞品投入集成。
3. **Rust终端平台**：Warp与WTA的竞争关系最直接。其README曾保留“尚未开源”的旧
	表述，但当前官方文档、AGPL许可证和完整Cargo源码树已经明确证明client已开源。
4. **混合Rust核心**：oh-my-pi应归为TypeScript主产品加Rust native core。对WTA而言，
	关键不是追求纯Rust，而是把性能敏感、跨平台和协议边界放在合适层级。
5. **实验性Rust实现**：Claw Code目前更接近原型和产品主张样本；在有可重复release、
	真实Windows验收、持续提交和用户采用证据前，不应进入主榜或接入优先队列。

## Markdown 渲染实现逐仓调查

本节基于加入本地multi-root workspace的源码逐仓记录。每个结论固定到调查时的commit，
重点追踪模型response从stream event到parser、styled terminal lines和最终显示的完整数据流。

### OpenAI Codex CLI

调查commit：`14a8ac89af0a3c9033c1fa4d747ec5d6333e9890`（2026-08-19，
`Prefer the most recent session when queueing by name (#39385)`）。

#### 技术栈与ownership

- Markdown parser是`pulldown-cmark 0.10.3`，关闭default features并显式启用table和
	strikethrough；没有使用`tui-markdown`。
- terminal UI是`ratatui 0.30.2`；syntax highlighting使用`syntect 5.3.0`和
	`two-face 0.5.1`；wrapping/display width依赖`textwrap 0.16.2`和
	`unicode-width 0.2.1`。
- Codex自有`codex-rs/tui/src/markdown_render.rs`负责把pulldown-cmark event投影为
	Ratatui `Line`/`Span`；`markdown.rs`再附加OSC-8 hyperlink metadata和本地路径处理。
- finalized history cell保存raw Markdown source，而不是parsed AST；窗口宽度或syntax theme
	变化时可以重新render。核心类型是`AgentMarkdownCell`。

#### 数据流

```text
ServerNotification::AgentMessageDelta
  -> chatwidget/protocol.rs::on_agent_message_delta
  -> streaming/controller.rs::handle_streaming_delta
  -> MarkdownStreamCollector（累积raw source）
  -> streaming/render.rs（稳定block + mutable tail）
  -> markdown_render.rs（pulldown-cmark -> HyperlinkLine/Line/Span）
  -> commit tick逐步送入scrollback + active tail重绘
  -> completion时完整source重新render
  -> AgentMarkdownCell保存source并按当前width/theme显示
```

主要入口：

- `codex-rs/tui/src/chatwidget/protocol.rs`：接收agent message delta。
- `codex-rs/tui/src/streaming/controller.rs`：stream buffer、newline gate、table holdback和
	finalize。
- `codex-rs/tui/src/streaming/render.rs`：判断增量render或full re-render。
- `codex-rs/tui/src/markdown_render.rs`：Markdown语义到terminal styles/layout。
- `codex-rs/tui/src/history_cell/messages.rs`：source-backed finalized cell。
- `codex-rs/tui/src/chatwidget/rendering.rs`：Ratatui viewport/scroll/display。

#### Streaming策略

Codex有实时显示，但不是每个网络chunk到达就立即parse，也不是全程显示raw text：

1. delta先追加到raw Markdown buffer；没有newline的尾部通常不提交到稳定scrollback。
2. 收到newline后只parse `raw_source[stable_source_len..]`；同一次pulldown-cmark pass既生成
	styled lines，也通过offset events记录顶层block起点。
3. 如果suffix中至少出现两个顶层block，最后一个block的起点成为新boundary；boundary之前的
	source只render一次并加入stable prefix，最后一个block继续作为可替换tail。
4. Reference link definition或inline visualization可能改变早先输出，因此强制完整source
	re-render，并重置source-level stable boundary。
5. Table另有controller-level holdback：pending header或confirmed table之后的rendered lines不进入
	stable queue，因为新增row可能改变所有column width。
6. open language-tagged code fence有独立`StreamingCodeHighlighter` fast path；遇到歧义
	closer、异常info string、CR/NUL或theme revision变化时放弃fast path，回到canonical
	full render。
7. response完成时始终对完整raw source重新render；再按已经发出的stable line数量切出仍需
	显示的remainder，并把raw source交给final transcript consolidation。

因此其准确描述是：**source accumulation + stable-block incremental commit + mutable-suffix
reparse + canonical final render**。`streaming/render_tests.rs`会在每个chunk后比较incremental
snapshot与full render，防止两套语义漂移。

#### Codex如何判断stable prefix

Codex没有让parser返回“未来绝不会改变”的信号，也没有缓存Markdown AST。它维护两个byte/line
边界，并以“最后一个顶层block永远mutable”作为普通路径的保守规则。

`MarkdownStreamCollector`只保存：

- 完整raw `buffer`；
- 已newline-commit的`committed_source_len`；
- 当前render width等少量stream状态。

`StreamingRender`另外保存：

- `stable_source_len`：raw source中不再重复parse的prefix结束byte；
- `stable_rendered_len`：`render.lines`中对应的已保留prefix行数；
- 当前完整render snapshot、reference/visualization flags和可选open-fence fast-path状态。

普通append算法是：

```text
pending_source = raw_source[stable_source_len..]
pending = parse_and_render_with_offsets(pending_source)

if pending包含至少两个顶层blocks:
    boundary = 最后一个顶层block的start byte
    newly_stable_source = pending_source[..boundary]
    newly_stable_lines = render(newly_stable_source)
    stable_source_len += boundary
    保留newly_stable_lines

重新render并替换pending_source中的最后一个block
```

`TopLevelBlockTracker`包裹`pulldown_cmark::Parser::into_offset_iter()`；它在遍历时维护
`depth`：

```text
depth == 0 且event是Start/Rule/Html
    -> 发现一个新的顶层block
    -> 记录event source range.start

Start(...) -> depth += 1
End(...)   -> depth -= 1
```

只有`block_count > 1`时才返回`last_top_level_block_start`。因此：

- 一个不断增长的paragraph只有一个顶层block，`stable_source_len`保持0，整段继续重parse。
- 一张不断增长的table也是一个顶层block，source prefix不会提前冻结。
- 出现第二个顶层block后，第一个block及更早内容才进入stable source prefix。
- 下一次append从新的`stable_source_len`开始parse，不再读取更早source。

例如：

```markdown
# Heading

First paragraph.

Current **par
```

parser看到Heading、Paragraph和最后一个Paragraph。最后一个Paragraph的start byte是boundary，
所以Heading和First paragraph进入stable prefix，`Current **par`继续mutable。

#### Source stable与screen stable不是一回事

Codex还有controller层的三个rendered-line位置：

```text
emitted_stable_len <= enqueued_stable_len <= render.lines.len()
```

- `enqueued_stable_len`之前的lines已经进入动画queue。
- `emitted_stable_len`之前的lines已经发到scrollback。
- 两者之后的lines才是active live tail。

普通文本默认可较快进入queue；Table才通过`TableHoldbackScanner`额外计算tail budget，把从table
header开始的全部rendered lines留在active tail。结构变化时，queued但尚未emitted的lines可以清空
并按最新snapshot重建；已经emitted的lines不能在active stream中倒退或替换。因此Codex的
“stable”是基于最后block规则和特殊holdback的工程判断，不是parser提供的绝对保证。

Reference definition通过`parser.reference_definitions()`检测。一旦出现，后续append走
full-source `recompute`；inline visualization、width变化和render mode变化也走full recompute。
Open code fence只有在top-level、language-tagged且closer判断无歧义时才进入增量highlight fast
path，否则继续canonical whole-fence render。

Finalization不拼接incremental AST：它完整render raw source，然后按`emitted_stable_len`执行
`split_off`，只返回尚未发出的canonical remainder。`render_tests.rs`在每个chunk后比较
`StreamingRender.lines`与当前完整source的cold render；这验证current snapshot等价，但不表示
已经发到scrollback的lines可以被回写。

#### Markdown显示能力

- Heading保留可见`#`marker；H1使用bold+underline，H2 bold，H3 bold+italic，H4-H6
	italic。
- 支持nested ordered/unordered list、emphasis、strong和strikethrough，并对multiline list
	item做缩进与间距处理。
- Web link使用cyan+underline并生成OSC-8 hyperlink；本地文件link会规范化并显示相对cwd
	路径。
- Fenced/indented code block先buffer；已知language在block完成后用Syntect高亮，未知language
	回退plain text。超出size/line limit时也安全回退无高亮文本。
- Table有独立`TableState`，按terminal display width计算column；宽度充足时输出aligned grid，
	窄viewport无法容纳时降级为stacked key/value records，并保留cell内部styles和links。
- 自有adaptive wrapping使用Unicode display width，覆盖CJK、emoji和combining characters。
- Image、footnote reference和task-list marker目前没有专属UI，相关event被忽略；普通link
	仍照常显示。

#### 额外处理与对WTA的启示

- Stable output通过adaptive commit ticks进入scrollback，形成可控的typewriter-like动画；
	mutable tail留在active transcript cell中。
- Syntax theme支持bundled light/dark和自定义`.tmTheme`；全局theme revision用于使render
	cache失效。
- parser只负责Markdown semantics；wrapping、hyperlink、animation、scroll/history和theme
	revision由外围层拥有。这与WTA当前ownership一致。
- WTA不必复制Codex复杂的block cache，但值得吸收四点：table streaming holdback、
	source-backed finalized message、theme/width变化重渲染、incremental-vs-full equivalence
	tests。

关键测试位于`codex-rs/tui/src/markdown_render_tests.rs`、
`codex-rs/tui/src/streaming/render_tests.rs`、
`codex-rs/tui/src/streaming/code_fence_render_tests.rs`和
`streaming/controller.rs`内的unit tests。

### goose

调查commit：`9f941fbfc5f479d26747d13147457138163ab94e`（2026-08-19，
`feat(cli): let --with-extension name its extension (#11127)`）。

#### 当前Rust CLI技术栈

- CLI Markdown presentation使用`bat 0.26.1`的`PrettyPrinter`，由bat间接使用
	`syntect 5.3.0`做syntax highlighting；没有使用pulldown-cmark、comrak、
	tui-markdown、Ratatui或termimad。
- Pipe table先被goose自己的detector截获，再用`comfy-table 7.2.2`输出；普通Markdown
	fragment才交给bat。
- `MarkdownBuffer`使用直接依赖的`regex 1.12.3`和自定义scanner识别streaming安全边界。
	它不是完整Markdown parser，也不保存AST。
- CLI配色根据terminal light/dark选择bat的`GitHub`或`zenburn`theme；bat wrapping被显式
	关闭，因此CLI没有统一的Markdown reflow/layout engine。

#### CLI数据流

```text
AgentEvent::Message
  -> crates/goose-cli/src/session/mod.rs（每个response建立MarkdownBuffer）
  -> session/output.rs::render_message_streaming
  -> streaming_buffer.rs::MarkdownBuffer::push
  -> 只释放语法边界安全的raw Markdown fragment
  -> output.rs::print_markdown
       -> pipe table: comfy-table
       -> other Markdown: bat::PrettyPrinter + ANSI
  -> stdout / terminal scrollback
```

主要入口：

- `crates/goose-cli/src/session/mod.rs`：response lifecycle和per-response buffer。
- `crates/goose-cli/src/session/streaming_buffer.rs`：stream safety scanner、checkpoint、
	unfinished syntax和large code truncation。
- `crates/goose-cli/src/session/output.rs`：stream event dispatch、bat renderer、table renderer、
	TTY/light-dark判断。

#### Streaming策略

goose CLI提供实时显示，采用**增量安全扫描 + 独立fragment重解析**：

1. model text chunk进入`MarkdownBuffer`；scanner跟踪fence、heading、table、inline code、
	emphasis、strikethrough、link和image URL是否闭合。
2. 只在“clean boundary”释放fragment，未闭合构造继续留在buffer，避免把半个link、bold
	marker或code fence交给bat。
3. scanner维护checkpoint，不会为每个chunk重新扫描已经稳定的line；但每个释放的fragment
	仍由bat独立parse/render，多个fragment之间没有共享Markdown AST。
4. tool call、error、notification或image要插入输出前，先flush Markdown buffer，保持event
	顺序。
5. stream结束时`flush()`会把仍未闭合的syntax按raw Markdown释放，保证模型输出不丢失。
6. finalized non-streaming message也调用同一个`print_markdown`，但streaming fragment boundary
	可能影响跨fragment语义，不具备Codex那种canonical full final re-render。

测试覆盖split bold、inline code、link、heading、table、fenced code、Unicode、malformed/
unfinished constructs和任意chunk boundary；另比较checkpoint incremental scan与full rescan
结果，但没有比较fragment render与完整Markdown render的视觉等价性。

#### CLI显示能力和限制

- Heading、list、emphasis、link、inline/fenced code主要由bat的Markdown syntax定义显示；
	code highlighting来自bat/Syntect。
- 大型fenced code达到阈值后会截断terminal内容，并把完整内容写入临时文件。
- Table不由bat处理：goose解析简单pipe table并重建为`comfy-table` ASCII Markdown style。
	cell作为plain string处理，不递归渲染cell内Markdown。
- `WrappingMode::NoWrapping(true)`关闭bat wrap；普通内容的换行主要交给terminal，table宽度
	由comfy-table和unicode-width处理。
- CLI没有app级scroll/history layout；conversation history重新走普通message renderer，滚动
	依赖terminal scrollback。
- 非TTY输出不会调用bat或table renderer，而是直接输出原始Markdown，便于pipe和脚本消费。

#### ACP、Desktop与旧TUI必须分开看

- **ACP不渲染Markdown**：provider/server只转发`AgentMessageChunk`文本和稳定的连续run ID；
	client决定如何显示，协议层不传ANSI、styled span或rendered representation。
- **Desktop是另一套实现**：ACP chunk先拼接到完整message string，React更新时交给
	`react-markdown 10.1.0`；插件链是`remark-gfm 4.0.1`、`remark-breaks 4.0.0`、
	`remark-math 6.0.0`、`rehype-katex 7.0.1`和`react-syntax-highlighter 16.1.1`。
	它随累计string变化反复parse；table/wrap走DOM/CSS，code用定制`oneDark`Prism theme。
- **原TypeScript ACP TUI已deprecated/removed**；当前Rust feature中的`goose tui`只负责启动
	旧external JS package，不是维护中的Rust TUI renderer，不能作为当前CLI架构依据。

#### 对WTA的启示

- 值得借鉴`MarkdownBuffer`对unfinished syntax的保守释放、event插入前flush和large code
	spill-to-file；这些都能改善streaming可读性和资源上限。
- 不建议复制“bat fragments + parallel table renderer”：它无法保证streaming与finalized
	完整文档完全等价，table cell Markdown和统一height/layout也较弱。
- ACP保持presentation-neutral是正确边界；WTA应继续在helper UI侧保存raw source，并让实际
	lines与height estimator共享同一个renderer。

### ForgeCode

调查commit：`6ed5d37b6b45a2b6220877fd9aec5ba4c4b7f3c0`（2026-08-08，
`chore(deps): update rust crate two-face to v0.5.2 (#3834)`）。

#### Surface与技术栈

ForgeCode普通chat不是Ratatui retained-mode TUI：Rustyline负责input，assistant output以ANSI
直接写stdout，scrollback由terminal拥有。它有两套Markdown renderer：

- **Live streaming**：`streamdown-parser/core/ansi/render 0.1.4` + ForgeCode自有
	`forge_markdown_stream` renderer；code highlighting用`syntect 5.3.0`。
- **Whole-message `conversation show`**：`termimad 0.34.1`渲染完整文档，code block先提取，
	再用`syntect`/`two-face 0.5.2+bat-0.26.1`高亮后放回。
- 两条路径均用`terminal-colorsaurus 1.0.3`判断terminal light/dark；live renderer还直接
	使用`unicode-width 0.2.2`和`unicode-segmentation 1.12`。

#### Live数据流

```text
provider ChatCompletionMessage chunks
  -> ResultStreamExt::into_full_streaming
  -> ChatResponseContent::Markdown { text: delta, partial: true }
  -> UI::handle_chat_response / UI::on_chat
  -> StreamingWriter
  -> forge_markdown_stream::StreamdownRenderer
  -> stateful streamdown_parser::Parser events
  -> ForgeCode semantic renderer
  -> ANSI writer / stdout / terminal scrollback
```

主要入口：

- `crates/forge_domain/src/result_stream_ext.rs`：provider delta标准化、raw response累积和
	`Markdown { partial: true }`event。
- `crates/forge_main/src/ui.rs`：interactive/direct/piped chat共同event loop。
- `crates/forge_main/src/stream_renderer.rs`：`StreamingWriter`。
- `crates/forge_markdown_stream/src/lib.rs`：line buffer、parser feed和finish。
- `crates/forge_markdown_stream/src/renderer.rs`：parser event到ANSI semantics。

`into_full_streaming`一边发送每个非空content delta，一边累积完整raw assistant response供
conversation持久化；没有单独发出`partial: false`Markdown event，完成由`TaskComplete`表示。

#### Streaming策略

ForgeCode采用真正的**stateful incremental parser**，不是full-buffer reparse：

1. `push()`把raw chunk追加到`line_buffer`；没有newline的unfinished line暂不显示。
2. 每个完整line先经过`repair_line`，再feed给同一个`streamdown_parser::Parser`；parser state
	跨line保留，生成的event立即写ANSI。
3. `finish()`处理最后一个无newline的line，再调用`parser.finalize()`输出剩余event。
4. 因此不会直接显示raw chunk，也不会在每帧重新parse完整累计response；不完整inline syntax
	的最终行为主要由`streamdown-parser`的state/finalize contract决定。
5. ForgeCode自己的repair只处理一个具体provider defect：已经在code block内时，把与代码
	黏在同一line末尾的`}` + closing ```/~~~拆开；不尝试修复任意bold/link/fence。
6. Table必须等到`TableEnd`才render，因为需要完整column数据；普通line仍可实时输出。

这条路径没有completion后的canonical full re-render。raw完整response会持久化，但已经写入
terminal scrollback的stream output不会被替换。

#### Markdown显示能力

`streamdown-parser`提供text、inline code、bold/italic/bold-italic、underline、strikeout、
link、image、footnote、heading、fenced code、ordered/unordered/task list、blockquote、
horizontal rule、table和thinking block event。ForgeCode在外围实现：

- Heading styles和width-aware wrapping。
- Nested list、ordered numbering、checkbox和continuation indent。
- Table使用box-drawing border；根据terminal width收缩column，最小column width为5；cell
	可保留inline styles并wrap。
- Code block使用Syntect；known language高亮，unknown language回退plain text。
- Wrapping按grapheme和Unicode display width切分，保留ANSI/OSC hyperlink sequence，并在
	换行后恢复active style；长token也可按grapheme安全拆分。
- Theme为ANSI color集合，分别定义heading、bullet、link、table、quote、thinking和inline
	code；terminal theme query每process一次，timeout 100ms，失败默认dark。

#### Interactive、one-shot和history

- Interactive mode、`--prompt`one-shot和piped stdin都调用同一个`UI::on_chat`和
	`StreamingWriter`，response格式相同。
- ZSH plugin通过`--prompt`启动Forge并把输出定向到`/dev/tty`；plugin只处理shell input/
	prompt，不parse assistant Markdown。
- `forge conversation show <id>`默认走另一套`forge_display::MarkdownFormat`/termimad完整
	文档renderer；`--md`则原样输出raw Markdown。
- Conversation保存raw assistant content；Rustyline只保存user input history。正常assistant
	output不保留render cache，也没有app-owned viewport/scroll offset。

#### 测试与WTA启示

`forge_markdown_stream`使用inline `insta` snapshots覆盖chunk boundary、Korean/CJK、heading、
inline formatting、nested quote/list、checkbox、table width/Unicode/style/wrap、embedded fence
repair和Syntect code wrapping。没有发现live `streamdown-parser`输出与whole-message
`termimad`输出的等价性测试。

- Stateful line parser能降低重parse和重绘成本，并保持低stream latency；代价是无newline时
	看不到进展，且历史terminal output无法用canonical result纠正。
- Table block buffering与Codex结论一致，说明table在streaming中确实需要特殊稳定性策略。
- 双renderer容易让live和history语义漂移；WTA当前finalized/streaming共享
	`agent_markdown_lines`更适合需要精确height和scroll的retained UI。
- `terminal-colorsaurus`读取外层terminal theme，不适合直接复制到拥有独立agent pane
	palette的WTA；WTA继续使用pane-relative `Color::Reset`更正确。

### Amazon Q Developer CLI

调查commit：`15cc8f3cd18c4272925ce1c7053268eedff1ea0a`（2026-04-23，
`Update README to include issue reporting link (#3775)`）；workspace版本`1.19.7`。
该开源项目当前只接收关键安全修复。

#### 技术栈与ownership

- Markdown由`chat-cli`中的自定义`winnow 0.6.2`parser实现，输入类型是
	`winnow::Partial<&str>`；没有pulldown-cmark、comrak、markdown-it、tui-markdown或
	termimad。
- 输出层是`crossterm 0.28.1`ANSI command；`unicode-width 0.2.0`用于terminal cell宽度。
- workspace虽声明`syntect 5.2.0`，但Markdown renderer没有使用它，code block只统一着色，
	不做language syntax highlighting。
- 原始assistant Markdown单独保存在conversation history；parser state和terminal presentation
	不进入持久化数据。

#### 数据流

```text
AWS/provider ChatResponseStream
  -> api_client/model.rs（统一AssistantResponseEvent等事件）
  -> cli/chat/parser.rs（逐delta发ResponseEvent::AssistantText，累积完整raw response）
  -> cli/chat/mod.rs::handle_response
       buf += delta
       ParseState跨delta保留
       parse winnow::Partial(&buf[offset..])
  -> cli/chat/parse.rs（Markdown子集 -> Crossterm commands）
  -> stdout ANSI 或 TextMessageContent { delta: Vec<u8> }
  -> completion后raw Markdown写入conversation history/database
```

主要入口：

- `crates/chat-cli/src/api_client/model.rs`：provider stream标准化。
- `crates/chat-cli/src/cli/chat/parser.rs`：response stream、delta和完整assistant message。
- `crates/chat-cli/src/cli/chat/mod.rs`：raw buffer、byte offset、persistent ParseState和output。
- `crates/chat-cli/src/cli/chat/parse.rs`：winnow grammar、wrapping和Crossterm style。
- `crates/chat-cli/src/cli/chat/conversation.rs`：raw Markdown history。

#### Streaming策略

Amazon Q使用**累计buffer上的stateful incremental parse**：

1. 每个assistant delta立即加入`buf`，同时由上游累积完整response。
2. renderer只parse`buf[offset..]`，成功消费后推进byte offset；`ParseState`保存code block、
	bold、italic、strikethrough、newline、当前display column、terminal width、citations和
	Markdown-disabled状态。
3. grammar遇到半个backtick、`**`、link prefix或fence prefix时返回`Incomplete`，caller保留
	这些bytes等待下一delta；不会把不完整marker先显示出来。
4. 新bytes到达后从同一offset继续parse，不重新parse已经输出的prefix，也不保存AST。
5. stream结束时人为追加newline，促使仍可解释的unfinished data flush；parser loop之间有固定
	8ms sleep，避免长期占用async loop。

它比ForgeCode的newline gate更细粒度，可以在line内安全token完成后输出；但没有completion
后的canonical full render，已写入terminal的ANSI不可替换。

#### 支持的Markdown子集

- Heading保留`#`marker并使用emphasis color + bold。
- `-`/`*`bullet转换为`•`；numbered list保留数字prefix。
- Blockquote将`>`转换成`│`；horizontal rule转换为重复`━`。
- Inline code去掉backtick并用success/green style。
- Fenced code去掉fence，language label加粗，整个body统一green；不做language highlighting。
- Bold、italic和strikethrough切换Crossterm attribute。
- Markdown link显示label，随后显示URL；`[[n]](url)`citation显示`[^n]`并收集URL作为footnote。
- 解码`&lt;`、`&gt;`、`&amp;`和`&quot;`。
- 不支持table、image、task list、完整nested structure和复杂ordered-list indentation；相关
	syntax大致作为普通文本输出。

#### Wrapping、theme和其他surface

- `WrapMode::Always`使用terminal width，`Never`关闭，`Auto`仅在stdout为TTY时wrap。
- 每个字符输出前用unicode-width更新display column并判断换行；考虑wide char，但不是
	grapheme-aware layout。Code block原样输出，不做width-aware wrap。
- Theme是process-global `DEFAULT_THEME`：primary white、secondary dark grey、emphasis
	magenta、code/success green、info blue；没有light/dark检测。普通文本reset后继承terminal
	default，但Markdown semantic colors是固定ANSI色。
- CLI直接写terminal，无app-owned viewport/scroll；assistant history保存raw Markdown，
	Rustyline history只保存user input。
- `chat-cli-ui`定义streamed bytes protocol并依赖`ratatui 0.29.0`，但当前app draw closure仍是
	空scaffold；legacy conduit只转发已经render好的ANSI bytes，不是第二个Markdown renderer。

#### 测试与WTA启示

`parse.rs`内unit tests覆盖plain text、inline code、links/citations、bold/italic/strike、heading、
lists、quote、rule、HTML entities、fenced code和Markdown-disabled；response parser另测tool/
code-reference events。没有发现按任意network chunk boundary驱动renderer的强测试或视觉
snapshot。

- `winnow::Partial`证明可以用小型state machine获得低延迟、零AST的streaming Markdown子集。
- 但它不适合WTA现有需求：resize无法重排已输出内容，table和syntax highlight缺失，固定ANSI
	色不可靠，且没有共享的rendered lines/height模型。
- 可借鉴的是raw conversation与presentation分离、partial token不提前显示、completion强制
	flush；不应复制其不完整grammar或direct stdout ownership。

### Warp

调查commit：`04a7f8342c0b78978f12ecd2a3e032ff439bd56f`（2026-08-18，
`Downgrade key-binding responder-chain report_error! to log::error! (#15299)`）。Warp当前有
三个必须分开的surface：GUI Agent Mode、自定义headless TUI和CLI/SDK文本输出。

#### Shared parser与依赖

- 共享`markdown_parser 0.1.0`是Warp自有crate，使用`nom 7.1.3`构建parser；另用
	`html5ever`/`markup5ever_rcdom 0.35.0`处理HTML相关内容、`serde_yaml 0.8.26`
	处理front matter等输入。没有pulldown-cmark、comrak或JavaScript Markdown runtime。
- Parser把Markdown转换成共享`FormattedText`：semantic `FormattedTextLine` + styled inline
	fragments + hyperlink metadata。GUI和TUI消费同一模型，但各自拥有layout/theme/render backend。
- Code highlighting走Warp editor stack：`warp_editor 0.1.0`、`arborium 2.13.0`和
	`arborium-tree-sitter 2.13.0`；不是该路径中的Syntect。
- `warp_tui`使用自定义`TuiElement`/cell-grid系统，不依赖Ratatui；GUI则是WarpUI自有GPU
	text/layout/paint系统。

#### Client数据流与Streaming

```text
agent response snapshot/update
  -> API conversion: AgentOutput / AgentReasoning
  -> parse_markdown_into_text_and_code_sections
       -> PlainText / Code / Table / Image / Mermaid sections
  -> AgentOutputText::from(current accumulated String)
  -> markdown_parser::parse_markdown（完整snapshot -> FormattedText）
  -> AIAgentText / AIAgentOutput（PartiallyReceived或final）
       -> GUI: FormattedTextElement + specialized section views
       -> TUI: TuiAIBlock::rich_text_sections -> TuiElement tree
  -> block dirty / remeasure / repaint
```

公开client没有incremental Markdown AST/parser state。每次output update都基于当前累计string创建或
更新section，并对当前完整plain-text snapshot重新parse；GUI/TUI block随后重建semantic
presentation。即：**full accumulated snapshot reparse**。服务端/provider如何组织token delta不在
此checkout中，源码只能确认client接收并重绘当前output snapshot。

主要入口：

- `app/src/ai/agent/api/convert_from.rs`：API output到agent model。
- `app/src/ai/agent/util.rs`：text/code/table/image/Mermaid section scanner。
- `app/src/ai/agent/mod.rs`：`AgentOutputText`保存original Markdown和cached
	`FormattedTextWrapper`，以及`reparse_markdown`。
- `crates/markdown_parser/src/markdown_parser.rs`：shared Markdown semantics。
- `app/src/ai/blocklist/block/model/model_impl.rs`和`block.rs`：streaming block update。

#### Unfinished syntax与section处理

- Section scanner先识别plain text、fenced code、GFM table、image和Mermaid；opening fence到EOF
	即使没有closer也会完成为Code section，因此streaming中的open fence能立即作为live code
	block显示和高亮。
- Unclosed emphasis/link/strikethrough/HTML comment走parser fallback：通常保留literal delimiter
	或降级为ordinary text，而不是等待完整token。
- 每次snapshot独立重parse使partial syntax恢复简单可靠；后续chunk闭合syntax后，旧snapshot
	的literal presentation会被新render替换。代价是长response每次更新都可能增加parse/layout成本。
- Table、image、Mermaid和code被提升为structured section，不与普通paragraph共享一个纯文本
	renderer；这让不同surface可分别布局。

#### GUI Agent Mode

GUI使用`FormattedTextElement`建立GPU-rendered text frames，拥有font、heading multiplier、
line-height、wrapping、hyperlink hit range、selection range、code layout和paint data：

- Prose使用AI font，code使用monospace，line-height约`1.2`；heading使用不同font倍率。
- List marker、emphasis/strong、clickable link和inline-code foreground/background都来自semantic
	fragments。
- Wrap由WarpUI text layout负责，不属于Markdown parser。
- Fenced code、structured table、image和Mermaid进入专门GUI component。
- Colors来自当前`Appearance`/GUI theme；selection、find和link hit-testing基于去除syntax marker
	后的semantic text，同时保留source section index。

这不是ANSI输出，也不是terminal emulator里的普通text block。

#### Warp TUI

TUI的`crates/warp_tui/src/tui_markdown.rs`只负责`FormattedText -> TuiElement`presentation：

- Body/muted/heading/link/inline code/code等palette role来自`TuiUiBuilder`当前theme；link是accent
	+ underline，heading/table header为bold body。
- 支持heading、ordered/unordered/task list、nested indent、bold/italic/underline/strike、
	inline code、link、image textual fallback、horizontal rule和block spacing。
- Link显示label；label与destination不同时额外显示URL。Image fallback为
	`Image: alt (source)`。
- Table按Unicode visible width计算preferred width，目标column约8 cells，以` │ `分隔；最小
	布局仍放不下时降级为`Name: Alice`式header-keyed records，并保留alignment metadata。
- Code/Mermaid使用按message ID + section index持久化的`TuiCodeBlockView`和
	`CodeEditorModel`。streamed code变化时更新buffer，Tree-sitter decoration异步刷新，并用
	buffer version拒绝stale highlight event。
- Code超过256 KiB或5,000 lines时UTF-8-safe截断并显示notice，回退bounded plain text。

`TuiAIBlock::rich_text_sections`按原顺序交错显示agent text、reasoning、tool call、todo、
received-agent message和summary。Transcript由canonical terminal block list拥有；dirty block在
当前width重新测量，`TuiViewportedList`/`TuiScrollable`维护scroll、selection和height cache。

#### CLI/headless与测试

- CLI/SDK `format_agent_text`把semantic section重新序列化为text/Markdown source：plain text
	直接写，code恢复fence，table/image/Mermaid使用保存的source；JSON/NDJSON序列化同一payload。
	它不做视觉Markdown terminal rendering。
- Parser unit tests覆盖heading、inline styles、lists、links、images、unfinished syntax和tables。
- `warp_tui` render-to-lines tests覆盖soft wrap、nested list、wide/narrow GFM table、code block、
	syntax colors、image fallback、height变化和viewport behavior；GUI另有agent mode integration
	tests。

#### 对WTA的启示

- Warp最值得借鉴的是“shared semantic model + surface-owned renderer/theme/layout”；每个snapshot
	只建立一次`FormattedText`，GUI和TUI无需各自重新解释Markdown semantics。
- WTA只有一个Ratatui surface，不需要引入持久AST；采用pulldown-cmark offset events维护
	`stable_source_len`即可减少stream重复parse，同时保留完整source canonical render。
- Code block值得独立持久state：stable message/section identity、async highlight和version guard比
	每帧完整Syntect parse更适合长stream。
- Table提升为structured section并提供narrow fallback，比依赖普通wrap更稳；WTA现有
	`tui-markdown`grid可继续使用，但可考虑增加stacked fallback。
- Theme必须由agent pane surface拥有。Warp的GUI/TUI各自读取自身palette，与WTA使用
	`Color::Reset`跟随agent pane scheme的原则一致。

### oh-my-pi (`omp`)

调查commit：`565d53515b54df32fada2564d1fe9caf1a17b738`（2026-08-19，
`feat(coding-agent): added providers.cacheRetention setting for prompt caching`）；workspace
版本`17.3.7`。该仓库是TypeScript主产品 + Rust native addon。

#### Ownership与依赖

Markdown完全由TypeScript UI层拥有，Rust不解析assistant Markdown、不维护AST/parser state、
不render heading/list/table，也不管理wrap或scroll：

- Parser是本地`@oh-my-pi/pi-utils/marked`，即项目自有的marked行为兼容实现，并非npm
	`marked`依赖。
- Terminal renderer是本地`pi-tui`的`Markdown`component；它同时负责lexer配置、token
	render、ANSI/OSC-8、width-aware wrapping、table layout、stream cache和settled-row metadata。
- Rust `pi-natives`只为fenced code提供N-API syntax highlighting：`syntect 5.3.0`，关闭
	default features，启用`default-syntaxes`、`default-themes`、`regex-fancy`和`yaml-load`。
- Rust还依赖`unicode-segmentation 1.13.3`和`unicode-width 0.2.2`等native utility；
	`tree-sitter-md 0.5.3`虽在lockfile中，但不参与assistant display renderer。

#### 数据流

```text
provider AssistantMessageEventStream
  -> pi-agent agent-loop（维护累计partial AssistantMessage snapshot）
  -> coding-agent AgentSession message_update / message_end
  -> interactive EventController（33ms UI update coalescing）
  -> streaming reveal（约30 FPS，按grapheme限制visible prefix）
  -> AssistantMessageComponent.updateContent
  -> one pi-tui Markdown component per text/thinking block
  -> marked-compatible lexer + custom terminal renderer
  -> ANSI rows / mutable transcript / native scrollback
  -> message_end保存authoritative raw AssistantMessage
```

主要入口：

- `packages/ai/src/utils/event-stream.ts`：normalized text/thinking/tool delta和final result。
- `packages/agent/src/agent-loop.ts`：累计immutable assistant snapshots。
- `packages/coding-agent/src/modes/controllers/event-controller.ts`：33ms UI coalescing。
- `packages/coding-agent/src/modes/controllers/streaming-reveal.ts`：grapheme reveal animation。
- `packages/coding-agent/src/modes/components/assistant-message.ts`：message block到Markdown
	component。
- `packages/tui/src/components/markdown.ts`：parser、renderer、wrap、table和stream cache。

Speech直接消费individual delta，不等待UI coalescing。`message_end`携带最终authoritative message；
UI replay总是从raw content重建Markdown component，不保存parsed token或ANSI。

#### Streaming与unfinished syntax

oh-my-pi采用**visible accumulated prefix reparse + frozen stable-prefix reuse**：

1. Agent loop发送当前累计assistant snapshot；UI每约33ms消费一次。
2. Reveal controller按grapheme count以约30 FPS增加当前可见prefix，减少provider chunk burst
	造成的跳跃。
3. `Markdown.setText()`解释当前visible prefix。完整block到达安全blank-line boundary后，其tokens
	和rendered rows可freeze；后续只lex/render未冻结tail，不必冷启动重做全部历史prefix。
4. Reference-link definition或CRLF等可能改变早先语义的输入会强制correctness-preserving full lex。
5. Open fence留在mutable tail；普通streaming code通常等block完成/freeze后才高亮。`diff` fence
	可对已完成rows做更积极的增量highlight。
6. Incomplete emphasis/link/fence按当前完整prefix的lexer解释，不保存独立unfinished delimiter
	state；后续prefix闭合后重新render即可纠正。
7. Tests在文档每个增长步骤比较incremental cache输出与cold full render，覆盖prose、fence、
	list、heading、mixed document、reference link、CRLF、replacement和loose list。

这保留了full-buffer snapshot模型的correctness，同时避免长response每帧重复render已经稳定的
block；比Warp单纯完整snapshot reparse多一层可验证cache。

#### Markdown显示能力

`pi-tui.Markdown`支持heading、paragraph、ordered/unordered/nested list、hanging indent、
emphasis/strong/strike、inline code、OSC-8 link、blockquote、rule、fenced code、GFM table、
HTML normalization、math extension和Mermaid：

- General wrapping使用ANSI-aware `wrapTextWithAnsi`；CJK/wide glyph按terminal visible width，
	ordered marker和tree-like Unicode prefix有专门hanging wrap。
- Table计算natural width、minimum unbroken-word width和可用width，再shrink/grow column、wrap
	cell并pad row。
- Table rows进入native scrollback后锁定column width，防止later row改变已经不可重绘的历史
	geometry。
- Active theme adapter提供`mdHeading`、`mdLink`、`mdLinkUrl`、`mdCode`、`mdCodeBlock`、
	`mdCodeBlockBorder`、`mdQuote`、`mdQuoteBorder`、`mdHr`和`mdListBullet`等semantic style。
- Fenced code仅在`nativeSupportsLanguage()`成功时调用Rust `nativeHighlightCode()`；highlight
	cache绑定当前theme，theme变化会invalidate。

Rust highlighter加载Syntect defaults并增加Julia、Nix和Mermaid syntax，把scope映射成11种
semantic color category，返回ANSI text；parse失败回退plain text。它不知道Markdown fence、
table、heading、list或TUI row。

#### Scrollback、ACP和其他surface

- `Markdown`报告frozen-prefix中byte-stable rendered rows；`AssistantMessageComponent`聚合active
	turn的settled rows，`TranscriptContainer`只把final block和声明稳定的prefix提交到native
	scrollback。
- **ACP**只转发raw `agent_message_chunk`和`agent_thought_chunk`，不调用terminal renderer。
- **Print text**输出final assistant text；**Print JSON**输出raw delta和authoritative
	`message_end`，不会输出累计partial snapshot。
- **RPC/headless**暴露raw message/event和`get_last_assistant_text`，不调用Markdown component。
- **HTML export**是独立HTML/CSS theme pipeline，不复用terminal Markdown renderer。

#### 测试与WTA启示

`packages/tui/test`中的`markdown.test.ts`、`markdown-incremental-lex.test.ts`、
`markdown-tree-wrap.test.ts`、`markdown-stream-prefix-cache.test.ts`和`markdown-math.test.ts`
直接检查ANSI剥离后的rows/visible width，并比较streaming与cold full render，不只依赖snapshot。

- 这是目前调查中与WTA需求最接近的streaming correctness设计：raw source authoritative、
	final/stream共享renderer、stable prefix cache、mutable tail reparse、table geometry与scrollback
	稳定性联动。
- WTA最终设计直接采用source-prefix cache；oh-my-pi最值得复用的是incremental-vs-cold
	equivalence tests、grapheme reveal和table/scrollback geometry contract，而不是其TypeScript lexer。
- Rust native boundary只承担昂贵且独立的syntax highlighting是合理取舍；不能把oh-my-pi归类为
	Rust Markdown renderer。
- Active pane theme传入highlighter、theme revision失效cache和scrollback row stability都值得
	WTA后续code highlighting设计直接参考。

### 跨仓实现对比

| 项目 | Markdown parser | Streaming模型 | 显示backend | Table策略 | Finalized/history策略 |
|---|---|---|---|---|---|
| Codex | `pulldown-cmark 0.10.3` + 自有Ratatui projector | newline gate；offset event冻结最后一个顶层block之前的source；特殊情况full recompute | Ratatui retained TUI + OSC-8 + Syntect | source层保持最后block mutable；controller另hold back完整table rendered lines | 保存raw source；completion canonical full render；按width/theme重render |
| goose | 自定义安全边界scanner；fragment交给`bat 0.26.1` | checkpoint增量扫描；clean fragment独立交给bat；结束raw flush | Direct ANSI/stdout；terminal scrollback | 独立`comfy-table`字符串renderer | 保存raw source；无canonical final replacement；desktop另用React Markdown |
| ForgeCode | `streamdown-parser 0.1.4` stateful parser | newline-gated incremental parser state；无full reparse | Direct ANSI/stdout；Syntect | 到`TableEnd`后box grid；按宽度收缩 | 保存raw source；live无final rerender；`conversation show`另用termimad |
| Amazon Q | 自定义`winnow::Partial` grammar | token级persistent ParseState；Incomplete等待下一delta | Direct Crossterm ANSI/stdout | 不支持 | 保存raw source；结束追加newline flush；无final rerender |
| Warp | 自有`nom` parser -> shared `FormattedText` | 当前累计snapshot完整重parse；block dirty/repaint | WarpUI GPU GUI或自定义TUI cell tree | 提升为structured section；responsive grid；窄宽度record fallback | 保存raw source + semantic cache；GUI/TUI共享semantics，surface各自layout |
| oh-my-pi | TypeScript marked-compatible lexer + `pi-tui.Markdown` | visible prefix重parse；safe block freeze；mutable tail重lex；grapheme reveal | TypeScript ANSI TUI；Rust Syntect N-API仅高亮code | width-aware cell wrap；进入native scrollback后锁column geometry | 保存raw source；stream/final共享renderer；history replay重parse |

### 对WTA的综合结论

1. **当前路线正确**：WTA的raw source authoritative、finalized/streaming共用
	`tui-markdown -> styled lines`、height消费同一projection，与Warp/oh-my-pi的correctness
	路线一致，也避开goose/ForgeCode双renderer语义漂移。
2. **直接采用Codex式source-prefix cache**：不维护跨chunk parser state，而是在同一次
	pulldown-cmark pass中取得styled output和top-level block offsets；保留最后一个block mutable，
	completion做current-response canonical full render。
3. **Table需要显式stream contract**：Codex/ForgeCode都会hold完整table，Warp提供narrow
	stacked fallback，oh-my-pi锁定已进入scrollback的column geometry。WTA已经保证height一致，
	下一步若改善窄pane可优先增加stacked fallback，而不是更换parser。
4. **Code highlighting应独立演进**：Warp和oh-my-pi都把code buffer/highlight从Markdown
	semantics分离，并以stable message/section identity、theme revision和buffer version管理cache。
	WTA未来可在现有parser后叠加该层，不必引入第二套Markdown renderer。
5. **Theme必须surface-owned**：固定dark theme或terminal-wide自动探测都不适合独立agent pane。
	继续以`Color::Reset`和agent pane semantic palette为基线；若增加syntax colors，应显式接收
	pane light/dark/theme revision。
6. **ACP继续传raw Markdown**：goose、Warp和oh-my-pi都把protocol/headless output与视觉
	renderer分开。WTA不应把ANSI、parsed AST或terminal lines放进ACP/session storage。
7. **避免复制的模式**：不要采用Amazon Q的不完整Markdown子集、goose的bat/table并行语义、
	ForgeCode的live streamdown + history termimad双实现，也不要让direct stdout ownership绕过
	WTA retained chat layout。

按最终设计的直接参考价值排序：**Codex > oh-my-pi > Warp > ForgeCode > goose > Amazon Q
CLI**。Codex提供与WTA最接近的Rust/pulldown-cmark/Ratatui source-prefix算法；oh-my-pi提供
最强的增量等价测试与grapheme reveal；Warp提供surface-owned semantic/layout边界。

## 第二轮：对Codex式最终设计的补强调查

本轮不再比较“谁的renderer更好”，而是以WTA已经选定的single canonical renderer、
`stable_source_len`、`PreparedChatLayout`、raw-source ownership和completion cold render为前提，
逐仓寻找可以补进最终设计的独立机制。每项分为直接采用、调整后采用和明确不采用。

### goose补强审计

调查commit仍为`9f941fbfc5f479d26747d13147457138163ab94e`。当前lockfile补充确认：
`regex 1.13.1`和`tempfile 3.27.0`；先前记录的`bat 0.26.1`、`comfy-table 7.2.2`和
`syntect 5.3.0`不变。

#### 直接采用

1. **统一event ordering barrier**：goose在tool request/response、action-required、image、error
	等事件显示前先flush当前Markdown buffer。WTA不需要flush raw source，但应建立同等强度的
	ordering contract：任何会插入chat transcript的非text event，必须先让当前assistant source
	到达一个确定revision并prepare对应mutable layout，再按ACP event顺序插入。这样tool/error/
	permission不会出现在属于它之前的text中间。
2. **Raw source永远完整保留**：任何stream preview、code truncation或disabled rendering只能改变
	projection，不能改变`ChatMessage::Agent`或history source。
3. **Random chunk differential tests**：goose会用不同chunk sizes、随机Markdown token、Unicode和
	malformed input比较checkpoint scan与full scan。WTA采用更强版本：每个随机append point比较
	`stable blocks + mutable tail`与cold `tui-markdown`的text、style、height和source consumption。

#### 调整后采用

1. **Checkpoint原则**：goose保存line-start scanner state和`last_safe`byte，并避免在纯
	whitespace/fence-like line上建立checkpoint。WTA不复制其hand-written grammar，但应要求
	`stable_source_len`只能在pulldown-cmark顶层offset boundary上推进，并将“无法安全分类”作为
	停止推进而不是猜测。
2. **Table holdback原则**：goose在table结束前不释放整个table。WTA的retained viewport可以继续
	显示mutable table，但在出现后续顶层block前不得把table加入stable block cache。
3. **大型fenced code预算**：goose以50 lines判定large block、terminal preview约20 lines，并将
	完整代码保存到文件。WTA只采用“限制昂贵projection”的原则：raw source始终完整，Markdown
	结构仍正确；对超阈值block限制syntax highlighting、可见preview或非viewport layout工作，阈值
	必须同时按bytes和lines定义并进入`PreparedChatLayout`height contract。
4. **Raw mode行为**：goose非TTY直接输出raw Markdown。对应WTA的`renderAgentMarkdown=false`
	应直接走plain projection，marker完整可见，parser调用计数为0。

#### 明确不采用

- 不采用“安全fragment分别交给bat”的renderer；fragment之间没有共享Markdown语义，且完成时
	不能canonical replacement。
- 不把goose `ParseState`作为CommonMark block判断器；它只覆盖部分syntax，不能替代
	pulldown-cmark offset events。
- 不采用独立`comfy-table`path；cell Markdown、styles、wrap和height必须继续由同一个canonical
	renderer拥有。
- 不采用bat的no-wrap/direct-stdout ownership。
- 不采用goose当前`tempfile.keep()`永久保留完整code的实现。若未来提供spill/open功能，必须使用
	package-private storage、byte quota、session/tab lifecycle cleanup和明确用户操作，且不能只把本地
	path写进assistant transcript。

#### 对最终设计的具体新增要求

- `PreparedChatLayout`的输入不只是message revisions，还必须包含ordered transcript item
	revisions；text、tool、error、permission等event共享一个单调顺序。
- 增加large-code projection budget和instrumentation：source bytes、line count、highlighted bytes、
	visible rows和fallback reason。
- 测试矩阵增加notification/tool event插入于partial Markdown之间的顺序测试；goose当前
	`McpNotification`有绕开Markdown buffer的路径，这正是WTA应通过单一barrier避免的缺口。
- 性能测试不能只证明近似linear；必须设parsed bytes、allocation、prepare duration和cache hit
	ratio的可观测指标。goose没有enforced benchmark budget，因此这里只采用测试形状，不采用其
	性能保证。

### ForgeCode补强审计

调查commit仍为`6ed5d37b6b45a2b6220877fd9aec5ba4c4b7f3c0`。依赖补充确认：
`streamdown-* 0.1.4`、`unicode-segmentation 1.12`、`unicode-width 0.2.2`、
`terminal-colorsaurus 1.0.3`和`syntect 5.x`。

#### 直接采用

1. **Grapheme-safe styled wrapping**：Forge把ANSI control sequence和Unicode grapheme作为不同
	atom处理，覆盖ZWJ emoji、combining marks和CJK。WTA不需要ANSI tokenizer，但
	`wrap_markdown_line`必须从`char + UnicodeWidthChar`升级为`Span style + grapheme cluster +
	display width`，保证一个grapheme不被拆到两行。
2. **Long token继续保留style**：长URL、inline code或连续非空白token被强制拆分时，每个续行必须
	保留原`ratatui::Style`和link metadata；不能先flatten为plain string再wrap。
3. **可见空白保真**：Inline spans之间的原始semantic separator应保留，不通过统一单空格重建。
	新增multiple spaces、styled boundary和link label/destination邻接测试。
4. **宽度property tests**：对任意grapheme string、style切分和viewport width，所有wrapped row的
	visible width不得超过可用宽度；拼接去除hanging prefix后的graphemes必须与输入semantic text
	一致，且style continuity不能丢失。

#### 调整后采用

1. **Table natural/minimum width模型**：Forge先计算cell natural visible width和minimum
	unbroken-token width，再按总宽度收缩column。WTA可采用该输入模型，但必须增加hard
	no-overflow保证：当border + minimum columns仍放不下时，降级为Warp/Codex式stacked records，
	不能坚持Forge固定5-cell minimum。
2. **Table fixture breadth**：加入very narrow、uneven rows、empty cells、CJK/emoji、rich inline
	cell、long unbroken token和alignment组合；每个fixture继续验证stream/final/height parity。
3. **Syntax资源cache**：若引入code highlighting，`SyntaxSet`/theme definitions等immutable asset
	可用`Arc/OnceLock`共享；每个fenced block仍使用完整、stateful highlighter处理multiline syntax，
	不能像Forge当前实现那样逐line新建highlighter而丢失跨行state。
4. **Projection-only provider repair只作条件兼容**：Forge能把code body末尾与closing fence黏在
	同一line的provider defect拆开。WTA只有在真实captured fixture证明某个支持provider稳定产生该
	问题时才增加窄规则；规则必须只作用于projection、保持raw source不变、同时用于stream和cold
	final render，并有provider-neutral regression tests。没有fixture时不实现。
5. **Markdown病态输入预算**：WTA现有generic 4096-char truncation不在
	`agent_markdown_lines`之前生效。需要对超长单行、超大code block和超宽table定义parse/layout/
	highlight budgets；fallback仍从完整raw source产生可解释preview，不修改history。

#### 明确不采用

- 不采用ANSI string作为table cell/layout ownership；WTA继续在typed `Line/Span`上测width。
- 不采用Forge固定5-cell column minimum；极窄pane必须stack或安全降级，不能横向溢出。
- 不使用`terminal-colorsaurus`查询process-global terminal并默认dark；agent pane palette是独立的。
- 不采用全局`base16-ocean.dark`/`InspiredGitHub`syntax theme选择。
- 不采用line-buffered streamdown direct stdout或live/history双renderer。
- 不把tool acknowledgement、parallel tool result reorder等stdout orchestration策略放进Markdown
	renderer；WTA继续使用ACP/turn-buffer authoritative ordering。

#### 对最终设计的具体新增要求

- `WrappedBlock`的最小layout atom改为styled grapheme，而不是Unicode scalar或flattened string。
- `PreparedChatLayout`新增debug invariant：每行visible width、prefix width和source/display mapping
	必须自洽；debug/test build遇到overflow立即失败。
- Table layout policy写成明确三阶段：natural widths -> bounded shrink -> stacked fallback。
- Code highlight cache只共享immutable resources；rendered highlight key仍包含source hash、language、
	theme revision和buffer version。
- 增加raw-source immutability test，确保任何compatibility repair、wrap、table fallback和toggle都
	不会改变`ChatMessage::Agent`。

### Amazon Q Developer CLI补强审计

调查commit仍为`15cc8f3cd18c4272925ce1c7053268eedff1ea0a`，workspace版本`1.19.7`；
相关依赖为`winnow 0.6.2`、`crossterm 0.28.1`和`unicode-width 0.2.0`。

#### 直接采用

1. **Byte offset纪律**：Amazon Q通过`&str`和Winnow `Offset`推进byte offset，只有parser真正消费
	完整UTF-8 slice后才移动位置。WTA的`stable_source_len`和`visible_byte_end`同样必须始终位于
	UTF-8 boundary；任何cache update先写blocks/lines，成功后再原子推进offset。
2. **Raw history与projection分离**：`AssistantMessage.content`保存完整raw string，ANSI/parser state
	不进入history。WTA保持同一contract。

#### 调整后采用

1. **已有Markdown-disable setting作为产品precedent**：Amazon Q定义
	`chat.disableMarkdownRendering`，但每个response创建`ParseState`时只读取一次，stream中修改不
	生效。WTA保留设计中的正向`renderAgentMarkdown`、helper bootstrap + live event；toggle是
	`PreparedChatLayout`projection mode，不是parser-global flag。
2. **Incomplete token不推进offset**：`winnow::Partial`遇到半个backtick/link/emphasis时保留
	`buf[offset..]`。WTA不复制custom parser state，但测试必须验证partial UTF-8/syntax append不会
	推进`stable_source_len`越过当前top-level mutable block，也不会丢失source bytes。
3. **Wrap mode与Markdown semantics分离**：Amazon Q有Always/Never/Auto和TTY判断。WTA不需要TTY
	分支，但应保持wrap只属于layout cache；`renderAgentMarkdown`只切换semantic projection，不能
	改变viewport width、prefix或scroll ownership。
4. **未来citation的数据模型**：Amazon Q只识别`[[n]](url)`并收集number/URL，未使用provider
	`CitationEvent`的location/range。WTA不采用该syntax；若未来支持citation，应以provider metadata
	+ raw source byte range + source/display mapping实现，并明确Unicode boundary。
5. **Style closure invariant**：Amazon Q依赖Crossterm reset，异常/partial stream可能造成ANSI style
	leak。WTA使用typed `Span`已经更安全，但测试应断言每个prepared row只包含显式semantic style，
	不会从前一row/message继承非预期background/attributes。

#### 明确不采用

- 不采用Amazon Q的custom Markdown subset或跨chunk `ParseState`。
- 不在completion时人为追加newline来推动parser；synthetic newline可能改变Markdown semantics，
	WTA应对原始source（包括无尾随newline）cold canonical render。
- 不采用固定8ms parser sleep；WTA使用event coalescing/reveal cadence，backpressure必须来自实际
	queue/frame metrics而不是固定延时。
- 不采用手写4种HTML entity decode或`[[n]](url)`citation grammar。
- 不把serialized Crossterm bytes作为structured output；WTA内部contract保持typed Ratatui
	`Line/Span`，ACP/history保持raw text。
- 不采用scalar-only wrapping或code-block no-wrap行为；统一使用styled-grapheme layout。

#### 对最终设计的具体新增要求

- `stable_source_len`、block `source_range`和`visible_byte_end`增加debug assertions：都必须是
	当前raw source的UTF-8 boundaries，且单调不减；source replacement是唯一reset路径。
- Random chunk generator必须包含落在UTF-8 multibyte内部的transport byte chunks；进入Rust
	`String`前完成合法解码，renderer只接收valid UTF-8 append。
- Completion tests必须覆盖无尾随newline的paragraph/list/fence/table，禁止测试fixture偷偷追加
	newline掩盖finalization defect。
- Toggle tests增加mid-response变化：Amazon Q只做到response-static，WTA必须证明live切换立即
	重project当前raw source且session/reveal/offset不丢失。
- 增加style-leak测试：连续render不同style的messages、partial syntax、toggle和error插入后，下一
	message的foreground/background/modifiers仍只由自身semantic style决定。

### Warp补强审计

调查commit仍为`04a7f8342c0b78978f12ecd2a3e032ff439bd56f`。相关组件是自有
`markdown_parser 0.1.0`、WarpUI/TUI retained element体系、Arborium/Tree-sitter editor pipeline
和`BufferVersion`。

#### 直接采用

1. **Dirty item + width-aware height cache**：每个transcript item以stable identity记录content
	revision、cached height和last measured width；只有dirty item或width变化时重测。WTA的
	`PreparedChatLayout`必须按message/completed-turn identity保存同类状态，streaming只dirty当前
	assistant item，selection/focus变化不dirty Markdown semantics。
2. **Viewport overhang/lazy measurement**：Warp只materialize visible band附近20 rows，其外item
	保持cached/lazy。WTA采用可配置的小overscan rows，viewport装配和toggle后的history重建只覆盖
	visible + overscan，禁止为了一个stream frame遍历完整conversation。
3. **Canonical item identity而不是screen row identity**：Warp使用BlockId/EntityId，row只是当前
	layout结果。WTA需要stable transcript item ID + intra-item source/row anchor；cache、selection、
	mouse hit和async result都不能只靠message vector index或absolute row。
4. **Height变化后的selection rebase**：Item rows增长/缩短时先生成row-resize change，位于变化之后
	的selection按delta移动；与被删除/不可映射rows相交的selection清除。WTA不能盲目保留旧screen
	coordinates。
5. **Code block明确资源上限**：Warp对TUI code view设256 KiB和5,000 lines上限，并做UTF-8-safe
	truncation + notice。WTA采用同类双阈值作为初始设计值或benchmark baseline；raw source仍完整，
	只限制highlight/editor-style projection。

#### 调整后采用

1. **Async highlight version token**：Warp复用`CodeEditorModel`并以expected `BufferVersion`读取
	decoration，stale result被拒绝。WTA若增加async highlighter，job/result key必须至少包含
	`(message_id, block_source_range, source_revision, language, theme_revision)`；任一不匹配即丢弃，
	不能覆盖新stream content。
2. **Structured table三档宽度**：Warp区分preferred width、minimum width并在放不下时降级
	header-keyed records。WTA与Forge审计合并为：natural/preferred -> bounded minimum shrink ->
	stacked fallback，同时保留cell semantic spans和selection source range。
3. **Logical selection/source mapping**：Warp在soft wrap处复制时不插入额外newline，并对mixed
	content回退rendered rows。WTA应让每个`RenderedMarkdownBlock`保留source byte range，每个wrapped
	row保留logical segment mapping；copy/selection使用logical text，不从painted cells反推source。
4. **Theme revision token**：Warp的Appearance event会全量invalidate但没有revision。WTA retained/
	async cache应显式递增`theme_revision`，使迟到的highlight/layout result可确定性失效。
5. **Viewport anchor**：Warp viewport使用absolute content rows；WTA在其上增加
	`(item_id, intra_item_row)`anchor，history上方插入、toggle reflow或table width变化后能恢复同一
	logical位置，而不是只clamp旧offset。
6. **Benchmark dimensions**：Warp覆盖100到10,000 blocks、long response、middle retained frame、
	invalidated frame和offscreen streaming tail。WTA直接采用这些规模，并额外拆分semantic parse、
	wrap/height、visible materialization、cache hit和stale async discard counters。
7. **FormattedTextDelta原则**：Warp parser能报告common-prefix line count，但TUI仍重建整棵element。
	WTA只在Codex mutable final block内使用类似delta作layout优化；source correctness仍由
	`stable_source_len`和cold render验证，不以line LCP代替block boundary。

#### 明确不采用

- 不把Warp Markdown link的“underline + literal URL suffix”当作交互实现；WTA若支持click，必须
	建立source span -> wrapped row/cell hit range，并接入现有action-link ownership。
- 不直接复制absolute-row viewport anchor；它无法正确穿越上方item插入/删除和reflow。
- 不把headless/raw output作为retained Agent Pane renderer。
- 不使用Warp自有parser/element framework替换`tui-markdown`/Ratatui。

#### 对最终设计的具体新增要求

- `PreparedChatLayout`改为item-indexed cache，item key稳定跨resize/toggle/stream append；每个item
	记录semantic revision、projection mode、measured width、row count和dirty reason。
- Viewport preparation只访问visible + overscan items；完整conversation总高度来自cached per-item
	heights和增量sum/tree，而不是逐frame重建所有items。
- Scroll保存semantic anchor而不仅是bottom-relative integer offset；auto-follow-bottom作为单独状态。
- Code budget、async highlight version token和theme revision加入Phase 3 contract，但code block
	identity/source range在Phase 2就建立，避免后续迁移cache key。
- Tests增加item上方插入、table reflow、toggle、width resize后selection/scroll anchor稳定性；Warp
	当前缺少完整end-to-end resize/reflow stabilization test，WTA需要补上。
- Link interaction留作显式feature：在没有source/display range map前只显示style，不声称clickable。

### oh-my-pi (`omp`)补强审计

调查commit仍为`565d53515b54df32fada2564d1fe9caf1a17b738`，workspace版本`17.3.7`。
其Markdown renderer、cache和reveal在TypeScript；Rust只提供native highlighting operation。

#### 直接采用

1. **Append lineage分类**：每次`setText`明确区分equal、append、truncate和unrelated replacement。
	只有append保留stream cache；truncate/replacement必须清除stable blocks、mutable rows、table/layout
	state和settled metadata。WTA为每条streaming message增加source lineage/generation，不只比较
	`source_revision`数字。
2. **33ms cumulative update coalescing + ordered flush**：同一窗口内只保留最新累计snapshot；在
	tool/error/permission/image、`message_end`和`agent_end`前同步flush最新text revision。与goose审计
	合并为WTA统一event ordering barrier。
3. **Grapheme reveal机制**：约30 FPS、minimum step和adaptive backlog catch-up；visible cursor在
	Markdown projection之前推进。WTA保留当前约4-frame catch-up作为初始UX contract，不直接改成
	oh-my-pi的8 frames；通过latency/CPU measurement调整常数。
4. **Component/item shape复用**：当message block结构未改变时复用同一cache item，只对active
	tail调用`setText`等价更新；不因每个delta重建历史item集合。
5. **Bounded cache原则**：oh-my-pi使用256 entries、总4 MiB、单entry 256 KiB的render LRU及
	256-entry highlight LRU。WTA采用“entry count + total bytes + per-entry bytes”三重上限和LRU
	eviction；具体数值以WTA line/span内存benchmark确定，不能让多tab长history无界增长。
6. **逐增长cold-equivalence tests**：每个append/reveal point比较incremental与cold output，覆盖
	reference、CRLF、replacement和list continuation。WTA扩展为rows/styles/width/height/table
	geometry/source consumption及toggle mode。

#### 调整后采用

1. **Reference definition preflight**：oh-my-pi在split lex前扫描definition。WTA优先使用同一次
	pulldown-cmark pass的`reference_definitions()`metadata；一旦出现，清空stable source assumptions并
	对current response full recompute。Regex只可用于测试/fast reject，不能成为authoritative grammar。
2. **CRLF与offset mapping验证**：oh-my-pi因lexer normalization在含`\r`时禁用split path。WTA的
	pulldown-cmark offset是否可直接映射raw CRLF必须通过fixture证明；若offset不能一一对应则整条
	message退回full parse。不能假设所有parser都与oh-my-pi相同。
3. **Render signature**：Stable rows/layout cache key除source lineage外，包含width、padding/prefix、
	projection mode、agent-pane theme revision、highlight revision和相关terminal capabilities。Signature
	变化只失效对应层，不修改source boundary。
4. **Highlight cache**：以`(language, code hash, theme revision)`为基础并受LRU预算约束；普通open
	fence只显示pane-relative code style，complete/frozen block才做完整highlight。`diff`若未来有专门
	line-independent fast path，必须另有tests和version token。
5. **Table width输入模型**：采用natural visible width + longest-unbroken-token minimum，与Warp/
	Forge审计合并；极窄时stacked fallback。oh-my-pi的raw-Markdown fallback不作为WTA目标。

#### 明确不采用

- 不叠加oh-my-pi的`stableBlockBoundary` blank-line/list lookahead作为第二套source boundary算法。
	它服务于marked-compatible split lex；WTA唯一authoritative boundary仍是pulldown-cmark top-level
	offset + last block mutable。额外规则只能让boundary更保守，不能自行推进它。
- 不复制native scrollback settled-row commit或table column lock。oh-my-pi一旦把rows提交到不可回写
	scrollback就必须锁geometry；WTA retained Ratatui viewport可重新layout mutable table，因此table
	在成为stable source block前保持可替换即可。
- 不采用oh-my-pi的raw-Markdown narrow table fallback；使用stacked semantic records。
- 不使用TypeScript marked-compatible lexer或把Rust native highlighter误当Markdown renderer。
- oh-my-pi没有assistant-response Markdown toggle precedent；WTA的toggle是明确产品要求，继续按
	Settings/runtime design实现。

#### 对最终设计的具体新增要求

- `StreamingMarkdownState`新增`source_generation`和append-lineage assertion；任何非append变化先
	递增generation，再丢弃所有旧async/cache result。
- Coalescer contract写入event pipeline：33ms是初始上限而非固定sleep；结构event/finalization必须
	flush latest text snapshot后再处理。
- Cache manager必须统计entry count、estimated bytes、evictions和oversize bypass；单个超大block
	可以不缓存，但仍正确render bounded viewport projection。
- Render/layout signature集中定义，避免semantic cache、wrapped rows、height和highlight各自遗漏
	toggle/theme/width invalidation字段。
- Differential harness对每个growth step同时运行enabled Markdown和disabled raw projection；后者
	必须证明parser调用为0，前者必须与cold canonical render一致。

### 第二轮采用结论

| 来源 | 采用到最终设计 | 不采用 |
|---|---|---|
| Codex | pulldown-cmark单pass offsets、`stable_source_len`、last top-level block mutable、reference full recompute、completion cold render | 不复制不可回写scrollback的emitted-line ownership |
| goose | ordered event barrier、random chunk differential tests、large-code projection budget | bat fragments、手写Markdown scanner、独立table renderer、永久temp spill |
| ForgeCode | styled-grapheme wrapping、long-token style continuity、table natural/min widths、width property tests | ANSI ownership、固定5-cell minimum、process-global theme、dual renderer |
| Amazon Q | UTF-8 byte-offset纪律、disabled projection安全contract、raw history、no-trailing-newline tests | custom grammar、synthetic newline、fixed 8ms sleep、ANSI byte protocol |
| Warp | item identity、dirty/width height cache、visible+overscan lazy layout、selection rebase、code limits、async version token、semantic viewport anchor | 自有parser/UI framework、absolute-row-only anchor、非交互link样式冒充click support |
| oh-my-pi | append lineage、33ms update coalescing、grapheme reveal、bounded LRU、render signature、每增长点cold equivalence | 第二套blank-line boundary、native scrollback/table lock、marked lexer |

合并后的设计只有一套Markdown correctness boundary：**pulldown-cmark top-level offsets**。其他项目
贡献的是event scheduling、Unicode layout、retained viewport、resource bounds、cache invalidation和测试
方法，不能新增第二套Markdown语法判断。

## 最终建议：面向 Stream 与 Performance 的 WTA Markdown 架构

### 一句话结论

对Intelligent Terminal最理想的方案是：

> **继续使用`tui-markdown -> WTA semantic styles -> Ratatui Line`作为唯一canonical
> renderer；扩展其底层pulldown-cmark pass，使同一次parse同时返回styled blocks和source
> offsets；在helper UI层采用Codex式`stable_source_len + final top-level block mutable`缓存；
> 以stable item identity、bounded cache和visible+overscan lazy layout管理retained history；用同一
> 份prepared layout同时服务height、viewport、selection和mouse hit-testing；completion时始终对
> 完整raw source做一次canonical full render。**

不应换成termimad/bat、JS `marked`、自定义`winnow`grammar或第二套stream parser。它们或者
接管terminal/layout ownership，或者制造stream/final语义分叉，或者牺牲CommonMark/GFM完整度。

### 为什么这最适合当前架构

WTA已经具备正确的基础边界：

- ACP/master只传raw assistant text；`TabSession`中的`ChatMessage::Agent(String)`是
	authoritative source。
- finalized message与pending stream都调用`agent_markdown_lines`，没有provider-specific
	Markdown语义。
- `tui-markdown 0.3.9`已提供pulldown-cmark/GFM table到Ratatui的成熟投影；WTA自己的
	stylesheet保证agent pane light/dark theme relativity。
- WTA拥有chat viewport、scroll、height、completed-turn mouse regions和pane identity，不能把
	rendering交给direct stdout、termimad或另一个terminal framework。
- 当前typewriter约30 FPS，并将可见延迟限制在约4 frames；这是presentation concern，不应污染
	parser或ACP source。

真正需要优化的是重复工作，而不是parser correctness。目前一次可见stream frame至少会：

1. 多次从头执行`chars().count()`和`chars().take(reveal_chars)`；
2. `layout::render -> estimated_block_height`完整构建一次message/turn/pending lines；
3. 随后`chat::render`在同一width再次构建相同lines；
4. pending prefix每次reveal tick都从头`tui-markdown` parse并wrap；
5. finalized history在频繁stream redraw中也可能被重复build/measure。

因此长response的当前成本接近“每帧扫描/parse当前完整prefix”，且同帧至少重复两次；当frame数
随response增长时，累计工作会趋近二次增长。最先消除这些重复，比替换Markdown库收益更确定、
风险更低。

### Planned Settings Toggle：启用或关闭Markdown渲染（尚未实现）

#### 用户设置contract

该toggle来自明确的Intelligent Terminal产品需求；它的实现主参考是项目现有
`ShowTokenUsageAndCost` Settings链路和`AgentRuntimeConfigSnapshot -> agent_config_changed`热更新
机制。Amazon Q的`chat.disableMarkdownRendering`只提供外部产品先例，并暴露了“每个response只读取
一次、不能mid-stream生效”的不足；它不是WTA toggle架构或命名的来源。

参考`ShowTokenUsageAndCost`的Settings model、ViewModel、XAML、localization和persistence测试
形状，新增一个全局正向boolean setting：

| 层 | 设计值 |
|---|---|
| C++ setting/property | `RenderAgentMarkdown` |
| JSON key | `renderAgentMarkdown` |
| Default | `true` |
| Settings header | `Render agent responses as Markdown` |
| Settings help text | `Format headings, lists, links, tables, and code in agent responses.` |
| Settings location | Settings > Agents，靠近`ShowTokenUsageAndCost`等agent presentation设置 |

默认`true`保持当前产品行为和现有用户体验。该设置只控制assistant response的视觉投影，不改变
agent能力、prompt、ACP协议、历史数据或provider输出。

此toggle不加入FRE：它不是登录、provider安装或首次使用的必要决策。Settings page中的
`SettingContainer + ToggleSwitch`是唯一用户入口；header/help text必须本地化并作为Automation
name/help text供screen reader使用。

#### C++到WTA的ownership

`ShowTokenUsageAndCost`只影响C++ bottom bar，因此不能直接复用它的runtime consumer；Markdown
renderer在每个`wta-helper`内，setting必须跨C++/helper边界。

采用bootstrap + live update两条路径：

```text
settings.json renderAgentMarkdown
  -> GlobalAppSettings::RenderAgentMarkdown
  -> AIAgentsViewModel / Settings ToggleSwitch
  -> TerminalPage::AgentRuntimeConfigSnapshot
       -> helper创建时: --no-agent-markdown（仅当setting=false）
       -> 运行中变化: agent_config_changed { render_agent_markdown: bool }
  -> wta-helper App.render_agent_markdown
  -> agent_response_lines选择Markdown或plain-text projection
```

Bootstrap约定：

- Clap新增helper-only `--no-agent-markdown`flag；负向argv与现有`--no-autofix`pattern一致，旧host
	不传flag时自动保持enabled。
- `HelperConfig`新增`no_agent_markdown: bool`；helper启动时设置
	`App.render_agent_markdown = !config.no_agent_markdown`。
- `_AutoCreateHiddenAgentPaneShared`读取当前global setting；关闭时向每个helper cmdline追加flag。
- 不把该flag加入`_BuildSharedWtaExtraArgs`或master config。Master不拥有UI renderer，也不应因
	presentation setting变化而respawn agent CLI。

Live update约定：

- `AgentRuntimeConfigSnapshot`新增`renderAgentMarkdown`，与autofix/delegate/catalog等可热更新
	settings一起比较。
- `_EmitAgentRuntimeConfigIfChanged`仅在值变化时发送optional
	`render_agent_markdown`field；不触发`AgentSettingsSnapshot`或`_RebuildAgentStack`。
- Event不带`tab_id`时fan out到window内所有visible、stashed和prewarmed helpers；每个helper在
	现有`agent_config_changed`handler中原地更新。
- 新helper始终从argv获得最新bootstrap值；现有helper从event立即更新。两条路径避免settings
	reload与pane创建并发时使用旧值。

#### Enabled与Disabled显示语义

统一通过一个projection boundary：

```rust
fn agent_response_lines(
    text: &str,
    wrap_width: usize,
    render_markdown: bool,
) -> Vec<Line<'static>>;
```

Enabled：

- 使用本文定义的`tui-markdown`/pulldown-cmark、Codex式source-prefix cache和WTA semantic
	styles。
- Markdown marker隐藏，heading/list/link/table/code按rich semantics显示。

Disabled：

- 完全绕过`tui-markdown`、block scanner和Markdown semantic cache。
- 使用现有plain-text dot-prefix/hanging-wrap路径，按raw source原样显示`#`、`**`、backtick、
	fence和table pipe等marker。
- Streaming和finalized message都调用同一个plain-text projection；height、viewport和mouse
	geometry继续消费同一`PreparedChatLayout`。
- 不改变raw `ChatMessage::Agent`、ACP chunk、reveal cursor、conversation history、session ID、
	model、tool call或turn lifecycle。

Toggle关闭不是“隐藏assistant output”，而是“显示未解析的raw Markdown”。这给用户提供明确、
可检查的fallback，也避免关闭后丢失模型返回内容。

#### 运行中切换状态机

`true -> false`：

1. 更新`App.render_agent_markdown = false`。
2. 清除当前helper所有Markdown semantic/block/highlight cache和Markdown-specific layout cache。
3. 保留raw messages、scroll offset、selection、turn/session和reveal position。
4. 从raw source为当前viewport及height planner建立plain-text `PreparedChatLayout`。
5. 下一frame立即显示raw marker；不重启helper、master或ACP session。

`false -> true`：

1. 更新`App.render_agent_markdown = true`。
2. 清除plain-text layout cache。
3. 同步cold-build当前streaming message和viewport覆盖到的finalized messages，保证下一frame正确。
4. 非可见finalized messages在滚动接近时从raw source懒加载，不在toggle handler中一次性重建
	整个conversation。
5. 若当前response仍在streaming，从完整current visible response建立初始
	`stable_source_len`/mutable-tail state，之后继续Codex式append算法。
6. 保持session、history、scroll和reveal position不变，下一frame显示rich Markdown。

切换会使当前conversation的projection cache失效，但同步成本只与当前viewport及streaming message
相关；非可见history按需重建。这是用户主动设置变化导致的一次性操作，不属于stream热路径。

#### Cache key与失效

所有assistant render/layout cache key必须包含`render_agent_markdown`或等价projection mode：

```text
(message_id, source_revision, projection_mode, width, theme_revision)
```

Markdown cache永远不能在disabled mode被读取；plain-text cache也不能在enabled mode被复用。
Toggle变化使projection mode整体失效，但不使raw source失效。

#### 实现ownership地图

Settings contract与UI：

- `src/cascadia/TerminalSettingsModel/MTSMSettings.h`：新增default-true global setting和JSON key。
- `src/cascadia/TerminalSettingsModel/GlobalAppSettings.idl`：投影Boolean setting。
- `src/cascadia/TerminalSettingsEditor/AIAgentsViewModel.idl/.h`：永久observable projected setting。
- `src/cascadia/TerminalSettingsEditor/AIAgents.xaml`：`SettingContainer + ToggleSwitch`。
- `src/cascadia/TerminalSettingsEditor/Resources/**/Resources.resw`：Header/HelpText localization。

C++ runtime bridge：

- `src/cascadia/TerminalApp/TerminalPage.h`：扩展`AgentRuntimeConfigSnapshot`。
- `src/cascadia/TerminalApp/TerminalPage.cpp`：capture/diff optional live field，并在
	`_AutoCreateHiddenAgentPaneShared`构建helper-only bootstrap flag。
- 不修改`SharedWta`master ownership或agent identity snapshot。

WTA helper：

- `tools/wta/src/cli/args.rs`、`main.rs`、`helper/config.rs`和`helper/runtime.rs`：bootstrap flag到
	`App.render_agent_markdown`。
- `tools/wta/src/app_events.rs`：应用optional live setting，清除projection-specific cache并redraw。
- `tools/wta/src/ui/chat.rs`及后续拆出的Markdown/cache module：统一enabled/disabled projection、
	Codex式stream cache和`PreparedChatLayout`。

Tests：

- `src/cascadia/UnitTests_SettingsModel/CustomAgentAndPolicyTests.cpp`：default/round-trip。
- TerminalApp相关unit tests：runtime snapshot/event wire和helper bootstrap arg。
- WTA chat/app/config tests：projection、hot toggle、cache/session invariants。
- `test/e2e/tests/Feature.SettingsUi.Tests.ps1`：Settings persistence。
- Markdown feature E2E：已连接、stashed/prewarmed和new helper的live/startup behavior。

### 目标数据流（Phase 0/1/2，尚未实现）

```text
ACP AgentMessageChunk
	-> ordered event coalescer（初始窗口上限33ms；结构event/finalize前flush）
	-> TabSession raw ChatMessage::Agent + source_revision + source_generation
	-> reveal scheduler（只推进visible byte/grapheme cursor，最多一次visible frame）
	-> ChatRenderCache::prepare(tab, width, theme_revision, render_agent_markdown)
			 -> stable item identity + dirty/width-aware finalized cache
			 -> enabled: streaming MarkdownDocumentCache
						stable_source_len之前  -> cached blocks + cached wrapped rows
						stable_source_len之后  -> single-pass parse/render with offsets
						最后一个top-level block -> mutable tail
			 -> disabled: raw plain-text projection（不调用Markdown parser/cache）
			 -> PreparedChatLayout
						total height
						visible + overscan rows / per-item row ranges
						completed-turn prompt geometry
	-> action-panel planner读取PreparedChatLayout.total_height
	-> chat renderer复用同一个PreparedChatLayout
	-> Ratatui Paragraph + mouse/action-link hit regions

completion
	-> 完整raw source canonical parse/layout一次
	-> 替换stream cache并存为finalized cache
	-> ChatMessage仍只保存raw source，不保存AST/ANSI/Line
```

### 两级缓存设计

#### 1. Semantic projection cache

建议引入UI-local `AgentMarkdownDocumentCache`，以stable message identity和source revision为
key，保存：

- raw source revision、append lineage `source_generation`、`visible_byte_end`和
	`stable_source_len`；
- `stable_source_len`之前的top-level source blocks及其logical styled lines；
- 当前mutable tail的source range和projection；
- 是否包含reference definition、open fence、active table等global/mutable construct。

当前`tui-markdown`只返回扁平`Text`，不暴露offset或block。设计要求扩展或维护一个最小fork，
新增streaming API，使**同一个pulldown-cmark parser pass**返回：

```rust
struct StreamingMarkdownRender {
	blocks: Vec<RenderedMarkdownBlock>,
	last_top_level_block_start: Option<usize>,
	has_reference_link_definition: bool,
	first_top_level_block_is_html: bool,
}

struct RenderedMarkdownBlock {
	source_range: Range<usize>,
	lines: Vec<Line<'static>>,
}
```

`RenderedMarkdownBlock`让WTA不必像Codex一样为了把source boundary映射回rendered-line count而
再次render newly-stable source。Parser event、source range和logical lines来自一次遍历，避免
并行运行第二个Markdown parser或维护重复grammar。

这一层不依赖viewport height。若`tui-markdown`logical output与width无关，resize只需要重做
layout；若未来某类block的semantic projection依赖width，则只将该block标记为width-sensitive。

#### 2. Layout cache

每个semantic block再缓存`(width, theme_revision) -> WrappedBlock`：

- 已加agent dot/hanging indent的`Vec<Line<'static>>`；
- exact rendered row count；
- table/code等block geometry；
- completed-turn prompt row/hit metadata；
- source/display mapping（未来OSC-8、selection或copy需要时使用）。

实际集中定义一个render signature，至少包括：

```text
(item_id, source_generation, source_revision, projection_mode,
 width, prefix/padding contract, agent_theme_revision,
 highlight_theme_revision, terminal_capabilities)
```

Cache受entry count、total estimated bytes和per-entry bytes三重LRU上限约束。Oversize block允许
bypass cache并按viewport需要render，不能因为无法缓存而拒绝显示或截断raw source。

`estimated_block_height`不再重新调用builder，而是对cached row count求和。`chat::render`也不再
重建同一内容，而是从同一个`PreparedChatLayout`装配viewport所需rows。这样height、实际display
和mouse hit-testing天然一致，不再靠两次独立计算保持同步。

Conversation总高度来自cached per-item heights及增量aggregate；每frame只materialize visible +
small overscan band。Scroll保存`(item_id, intra_item_row)`semantic anchor和独立
`follow_bottom`状态，不只保存absolute row offset。

缓存必须只属于helper UI/runtime，不进入：

- `ChatMessage`持久模型；
- ACP/master协议；
- session registry/history；
- C++ `TerminalControl`。

### Streaming算法

#### Step A：合并event与redraw

- `AgentMessageChunk`只追加raw source、增加`source_revision`并唤醒reveal scheduler。
- 如果visible cursor没有变化，单纯收到更多backlog不应立即重复parse同一visible prefix。
- 以33ms作为初始coalescing上限，只保留最新累计text snapshot；每个visible frame最多prepare一次
	Markdown。
- Tool/error/permission/image等结构event，以及`message_end`/`agent_end`，必须先同步flush最新text
	revision，再按authoritative event order处理和redraw。

这保留当前低延迟typewriter体验，同时避免`AgentMessageChunk`和紧随其后的`RevealTick`对同一
prefix连续render两次。

#### Step B：用byte/grapheme cursor替代反复chars扫描

当前`reveal_chars`每帧都需要从string起点count/take。应改为append-aware cursor：

- raw append时只统计新slice中的grapheme/character boundaries；
- 保存`visible_byte_end`、`visible_graphemes`和`total_graphemes`；
- 每个tick从上次byte offset继续走，不从头扫描；
- slicing直接使用`&text[..visible_byte_end]`，不重新collect整个prefix；
- 按grapheme而非Unicode scalar reveal，避免combining mark、ZWJ emoji或旗帜被拆成视觉半字符。

可使用`unicode-segmentation`，也可先维护UTF-8 char boundary cursor；是否增加依赖由benchmark
和Unicode UX test决定。无论哪种实现，cursor必须支持source replacement/shrink时安全reset。

同一个grapheme utility也用于Markdown layout：`wrap_markdown_line`以
`(ratatui::Style, grapheme, display_width, source range)`为最小atom；长token拆行时保留style/link
metadata和semantic whitespace。Reveal与wrap必须使用一致的grapheme boundary定义。

#### Step C：Codex式stable source prefix + mutable final block

每个visible prefix增长时执行：

```text
pending_source = visible_source[stable_source_len..]
pending = parse_render_blocks_with_offsets(pending_source)

if pending包含至少两个top-level blocks:
    final_block_start = pending.last_top_level_block_start
    stable candidates = final block之前的连续blocks
    把candidates追加到stable block cache
    stable_source_len += final_block_start

用pending中的最后一个top-level block替换当前mutable tail
```

执行前先验证append lineage：old source必须是new source前缀且`source_generation`相同。Equal只复用
cache；append走incremental path；truncate/unrelated replacement先递增generation，再丢弃全部旧
block/layout/highlight result并cold rebuild current response。

##### `stable_source_len`的精确更新时间

`stable_source_len`不是在收到每个network chunk时更新，也不是parser一产生`End`event就更新。
它只在一次stream prepare满足以下条件后推进：

1. 新增source已经进入当前visible prefix；若采用Codex相同的newline gate，则至少有新的
	newline-terminated source可commit。
2. 当前是rich Markdown mode，没有走raw-text bypass。
3. 本次没有被open-code-fence专用fast path完整处理。
4. 当前response没有reference definition、inline visualization或其他要求full recompute的
	document-wide construct。
5. 对`visible_source[stable_source_len..]`完成一次pulldown-cmark parse/render。
6. 该pending suffix中发现至少两个top-level blocks，因此
	`last_top_level_block_start = Some(boundary)`。
7. `boundary`之前的blocks及其styled lines已经成功加入stable block cache。

完成第7步后才原子地更新：

```rust
stable_source_len += boundary;
```

这里使用`+=`，因为`boundary`是相对于本次`pending_source`起点的byte offset，不是相对于完整
response开头的绝对位置。更新后`stable_source_len`正好指向当前最后一个top-level block的开头。

示例一，初始状态：

```markdown
First paragraph
```

只有一个顶层Paragraph，因此：

```text
stable_source_len = 0
整个Paragraph保持mutable
```

新增第二个Paragraph：

```markdown
First paragraph

Second paragraph
```

假设第二个Paragraph在完整source的byte 17开始。本次pending source也从0开始，所以：

```text
last_top_level_block_start = 17
stable_source_len = 0 + 17 = 17
```

First paragraph进入stable cache；Second paragraph保持mutable。

再新增第三个Paragraph：

```markdown
First paragraph

Second paragraph

Third paragraph
```

本次只parse `source[17..]`，其中Third paragraph假设在相对byte 18开始：

```text
last_top_level_block_start = 18
stable_source_len = 17 + 18 = 35
```

Second paragraph进入stable cache；Third paragraph成为新的mutable final block。

以下情况不更新`stable_source_len`：

- 新chunk尚未进入visible prefix，或newline gate尚未commit它。
- Pending suffix仍只有一个paragraph/list/quote/table/code block。
- 只有parser内部nested block结束，例如`End(Item)`或list内部`End(Paragraph)`。
- Open code fence fast path只追加了新的highlighted code lines。
- Source append后没有形成新的top-level block。

以下情况清空或重建source-level cache，并将`stable_source_len`重置为0：

- source replacement、shrink或不再满足append-only contract；
- parser options或会影响Markdown semantics的配置变化；
- reference definition、inline visualization或其他global rewrite要求full recompute。

Width或theme变化通常不改变source block boundary：可以保留`stable_source_len`，只使wrapped/
styled layout cache失效。但如果当前semantic projector本身依赖width/theme，则保守地重建当前
message cache。

顶层block由同一pulldown-cmark event stream识别。Tracker维护`depth`：

```text
depth == 0 且event是Start/Rule/Html
    -> 新top-level block，记录source range.start

Start -> depth += 1
End   -> depth -= 1
```

只有发现至少两个顶层blocks时才推进`stable_source_len`。这意味着：

- 一个持续增长的paragraph始终完整重parse，不从paragraph中间切分。
- 一个持续增长的list、blockquote、table或open code fence也始终是最后一个mutable block。
- 新的顶层block出现后，它之前的完整blocks才进入stable source prefix。
- 下一次只parse新的`source[stable_source_len..]`，不再读取更早source。

WTA采用Codex的source-boundary算法，但**不复制Codex的`enqueued/emitted scrollback`策略**。
Codex已经发到terminal scrollback的lines不能回写，因此需要额外TableHoldbackScanner；WTA拥有
retained Ratatui viewport，mutable tail可以在下一frame整体替换。WTA只需要保证table在后续
顶层block出现前不进入stable block cache，不需要把table从屏幕上隐藏。

特殊回退规则：

- **Reference link definition**：通过pulldown-cmark parser metadata检测；它可能改变前文，立即
	清空source-level incremental assumptions，对当前完整response执行full recompute，并在该
	response剩余stream中禁用stable-prefix推进。
- **Inline visualization或未来global rewrite**：若引入会改变其他block的syntax，同样full
	recompute并禁用prefix推进。
- **Source replacement/shrink、parser options变化**：清空stream cache，从完整current response
	重建。
- **Width变化**：source boundaries可保留，但wrapped layout全部失效；如果semantic output本身
	width-sensitive，则该message完整重建。
- **Theme revision**：source boundaries可保留，styled/layout cache失效。
- **Open code fence**：第一版只重parse整个final block；Codex式incremental highlighter作为后续
	独立优化，不是正确性依赖。

Completion时忽略incremental拼接，对当前完整raw response做一次cold canonical render；结果替换
mutable layout并成为finalized cache。测试必须在每个append point验证：

```text
cached stable blocks + mutable tail render == cold full render
```

### Table与code block的专项策略

#### Table

- Streaming open table整体属于mutable tail，不提交其中部分rows为stable。
- 当前grid renderer继续作为canonical结果；height直接来自同一wrapped rows。
- Layout执行三阶段：natural/preferred cell widths -> bounded minimum shrink ->
	header-keyed stacked fallback。任何阶段都必须保证visible width不超过viewport。
- 若未来把rows提交到不可重绘的native scrollback，必须像oh-my-pi一样锁column geometry；当前
	WTA retained viewport可重绘，因此暂不需要锁宽。

#### Code block

- Markdown parsing继续只识别fence/language/body；syntax highlighting是独立可选层。
- Open fence在streaming时使用轻量pane-relative code style，不要每3个reveal字符跑Syntect。
- 以256 KiB或5,000 lines作为初始expensive-highlight/editor projection上限；UTF-8-safe fallback
	显示bounded preview和notice，raw fenced source仍完整保留。最终阈值由WTA benchmark调整。
- Closed/finalized block按`(source_hash, language, theme_revision)`缓存highlight结果。
- 若要live highlight，只处理已完成line，并用stable message/section ID + buffer version拒绝stale
	async result，参考Warp/oh-my-pi。
- Light/dark palette必须从agent pane theme contract传入；禁止固定`oneDark`或hardcoded white。
- Immutable syntax resources可共享；async result必须匹配
	`(item_id, block_source_range, source_generation, source_revision, language, theme_revision)`。

### 精确失效规则

| 变化 | Semantic cache | Layout cache | 说明 |
|---|---|---|---|
| append ordinary stream text | 从`stable_source_len`只parse pending suffix | 只替换pending blocks | 热路径 |
| reveal cursor推进但未产生新顶层block | stable prefix不变，重parse final block | 只替换final-block rows | 不碰final history |
| response finalize | cold full rebuild一次 | cold full layout一次 | canonical correctness gate |
| pane width变化 | 通常保留logical semantics | 当前width全部失效并rewrap | 不重读ACP/source |
| agent pane theme revision | styles/highlight失效 | 全部失效 | 不读取普通terminal profile theme |
| completed turn expand/collapse | message semantics可复用 | 对应turn组合/geometry失效 | 其他turn不动 |
| selection/focus变化 | semantics不变 | 只更新selection overlay/style | 避免重parseMarkdown |
| `renderAgentMarkdown` toggle | projection mode全部失效，raw source保留 | 当前helper全部失效并按新mode重建 | 不重启session/ACP |
| source replacement/shrink | `source_generation += 1`，全部semantic/async result失效 | 当前message全部失效 | cold rebuild current response |
| reference definition/global construct | 相关document semantics全失效 | 全失效 | 保证CommonMark一致 |

### 复杂度目标

设当前response长度为$n$，本次新增或mutable tail长度为$\Delta$，可见frame数为$F$：

- 当前热路径近似$O(Fn)$，并有height/render双份projection；持续逐字增长时实际容易呈现二次
	累计成本。
- Prepared layout + byte cursor后，即使暂不做block freeze，也可消除同帧重复parse、重复prefix
	copy和final history重建。
- Stable block cache启用后，正常append frame目标为$O(\Delta + \text{mutable tail})$；
	finalization保留一次$O(n)$ canonical render。
- Resize是显式$O(n)$ rewrap，theme变化是显式$O(n)$ restyle/highlight；二者不是stream热路径。
- Viewport assembly应与可见rows及少量overscan成正比，而不是与完整conversation history成正比。
- Item上方插入/reflow不触发全history layout；只更新per-item height aggregate并用semantic anchor
	rebase viewport/selection。

不要在没有measurement时承诺绝对毫秒值。应先记录：每frame parsed bytes、wrapped chars、
Markdown calls、cache hit ratio、prepared-layout duration和chat render duration，再在目标Windows
x64/ARM64设备上设p95 budget。

### 推荐落地顺序

#### Phase 0：建立基线

- 给`agent_markdown_lines`、height preparation和chat render增加debug-only counters/timing。
- 建立10 KiB、100 KiB、100到10,000 transcript items和包含table/code/Unicode的stream corpus
	benchmark。
- 记录当前每个visible frame的parse次数、parsed bytes和allocation。

#### Phase 1：低风险最高收益

1. 新增`PreparedChatLayout`，一次prepare同时供action-panel height与chat render使用。
2. 引入stable item identity、dirty reason、width-aware per-item height cache、增量height aggregate及
	visible+overscan materialization；只重建changed item。
3. 将reveal改为append-aware byte/grapheme cursor，消除每帧prefix count/copy。
4. 将Markdown wrap升级为styled-grapheme atoms，并建立width/style/source preservation properties。
5. 实现33ms上限的chunk coalescer和结构event ordering barrier，保证每visible frame最多一次
	Markdown projection。
6. 新增`RenderAgentMarkdown`setting、helper bootstrap flag、live runtime event和统一
	`agent_response_lines`projection boundary。

这一阶段不改变Markdown semantics，应该先完成。

#### Phase 2：Codex式source-prefix stream cache

1. 扩展`tui-markdown`，让一次pulldown-cmark pass返回rendered blocks、source ranges和
	`last_top_level_block_start`。
2. 新增`stable_source_len`、stable block cache和mutable final block。
3. Reference definition/global rewrite触发current-response full recompute并禁用后续prefix推进。
4. Table/open fence/list/quote只要仍是最后一个top-level block就保持mutable。
5. completion cold full render替换incremental结果。
6. 对每种chunk boundary验证incremental rows与cold rows完全一致。

Phase 2是目标架构的一部分，不再以“完整prefix每frame重parse”作为最终可接受方案；Phase 0/1
仍先独立落地，以隔离性能基线、cache ownership和behavior change，降低单个PR风险。

#### Phase 3：体验增强

- Narrow-table stacked fallback。
- 独立、bounded、theme-aware、versioned code highlighting cache及large-code fallback。
- OSC-8 links和更精确的source/display mapping（若产品需要click/copy）。

### 必须建立的正确性门槛

- 对同一Markdown corpus的每个append point比较incremental output与cold full render：text、span
	style、row count必须一致。
- Random chunk boundaries，包括UTF-8 multibyte与grapheme cluster边界。
- Unclosed `**`、backtick、link、fence、list、quote、HTML和reference definition。
- Wide/narrow table、later row扩列、CJK/emoji/combining marks。
- Streaming/finalized exact parity；actual rows与height exact parity。
- 任意width resize、agent pane light/dark theme revision、completed-turn expand/collapse。
- Long response中input、mouse selection和scroll不能被render frame阻塞。
- Cache memory有上限；tab关闭、message删除、source replacement和theme change不会留下stale lines。
- 任意item上方插入、height变化、toggle和resize后，semantic scroll anchor与selection正确rebase。
- Tool/error/permission/image插入partial Markdown时，显示顺序与authoritative event order一致。
- Property tests保证每个wrapped row不超过viewport，grapheme不拆分，style/link continuity不丢失。

#### Toggle专项测试

Settings/model与UI：

- `renderAgentMarkdown`缺省为`true`，JSON显式`false/true`可round-trip。
- Settings > Agents toggle显示、键盘可操作、Automation name/help text正确，并持久化JSON。
- 所有支持locale和pseudo-locale包含Header/HelpText；不要只更新en-US。

Helper/runtime：

- `--no-agent-markdown`只影响helper初始projection，不进入master config。
- `agent_config_changed.render_agent_markdown`可以原地切换existing/stashed/prewarmed helper；field
	缺省时保留原值。
- 切换前后ACP SessionId、agent process、raw transcript、tool state、scroll和reveal cursor不变。
- Toggle关闭后Markdown parser调用计数为0，且旧Markdown cache不可命中。

Rendering：

- Enabled时heading/bold/link/code/table继续按现有rich contract显示。
- Disabled时同一corpus的`#`、`**`、link destination、fence和table pipes均可见。
- Streaming partial syntax、finalized message、multiple paragraphs、CJK/emoji和窄width在两种mode
	下actual rows与height完全一致。
- Streaming中双向切换多次不丢字、不重复行、不panic；最后completion仍保存完整raw source。

E2E：

1. Persisted default/enabled值启动新helper并显示rich Markdown。
2. 已连接helper运行中关闭toggle，raw markers立即出现且helper/session PID/identity不变。
3. 再开启toggle，rich rendering恢复且history不丢失。
4. Stashed/prewarmed helper和之后新建的helper都获得最新值。
5. 验证multiple lines、table和narrow pane；敏感prompt/log/screenshot继续只留dev/local artifacts。

### 明确不采用

- 不把Markdown parser移到C++ `TerminalControl`。
- 不在ACP/master/session history中保存AST、ANSI或Ratatui lines。
- 不把Markdown toggle放进master/provider identity，不因切换而restart agent或recreate session。
- 不嵌入JS runtime运行`marked`；无法获得OpenTUI renderer，却增加跨runtime和package成本。
- 不用Amazon Q式自定义Markdown子集换取微小stream latency。
- 不用goose的bat + parallel table renderer，也不用ForgeCode的streamdown + termimad双renderer。
- 不让Syntect/Tree-sitter成为Markdown correctness parser。
- 不实现跨chunk持久Markdown parser state；采用pulldown-cmark offset pass + source-prefix cache，
	并以completion cold full render作为canonical结果。

最终目标不是“最快的parser microbenchmark”，而是：**每个可见frame只处理真正变化的source，
streaming永远能被canonical full render验证，height/display/hit-testing永远消费同一layout，且
agent pane theme与ACP ownership不被破坏。**
