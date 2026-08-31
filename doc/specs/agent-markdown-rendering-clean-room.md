---
author: Clean-room requirements team (待指定)
created on: 2026-08-24
last updated: 2026-08-24
issue id: N/A
status: Draft
---

# Agent Markdown Rendering Clean-Room 重实现规范

## 文档状态与使用边界

本文档同时定义 Agent Markdown Rendering 的黑盒产品要求和 clean-room 执行协议。目标是让没有接触过隔离资料的团队，仅依据获批规格和公开标准，从干净基线重新实现完整功能。

本文档不是法律意见，也不证明 clean-room 已经成立。它由可能接触过既有实现或研究材料的需求侧起草，因此在发给实现团队前，必须由开源合规或法务负责人确认其仅包含功能、接口、约束和可观察结果，没有携带受保护的代码表达。

在以下条件全部满足前，不得把任何产物称为“clean-room implementation”：

- 法务或开源合规负责人书面批准本流程、本规格和允许资料清单；
- 实现团队完成接触史声明，并被确认没有接触隔离资料；
- 实现团队只在经过校验的干净源码快照上工作；
- 所有需求问答通过协调人过滤并留档；
- 独立审计完成来源、依赖、代码相似度和许可证检查。

隔离资料的项目名称、仓库地址、提交、文件和访问记录必须保存在访问受限的 source register 中，不得补充到发给实现团队的本文档副本里。

本文档中出现的 JSON key、CLI option、runtime event 和 wire field 是为保持跨组件兼容而固定的外部接口。除此之外，类型、函数、模块、状态字段、缓存、counter 和测试名称都由实现团队独立决定。

## 目标

重实现完成后，用户应获得以下能力：

- Agent 回复默认以 Markdown 语义显示；
- streaming、完成态和历史态采用一致的显示语义；
- 用户可在 Settings > Agents 中即时关闭或重新开启 Markdown 显示；
- 关闭后显示原始 Markdown 标记，且不重启 helper、master、agent 或会话；
- 原始回复始终是唯一持久数据，显示结果可以随宽度、主题和设置重新生成；
- 长回复、长历史、多标签页、Unicode、表格、resize、scroll、selection 和鼠标交互保持正确且响应及时；
- 解析、布局和缓存的内存及工作量有明确上限。

## 非目标

本工作不要求：

- 复刻任何第三方应用的内部算法、数据结构、命名、测试或视觉细节；
- 改变 ACP 消息格式、agent 身份、会话身份或历史存储格式；
- 在 C++ Terminal UI 层解析 Markdown；
- 执行 Markdown 内的代码、HTML、图片、脚本或远程资源；
- 为 fenced code 增加语法高亮；
- 增加 provider-specific Markdown 方言；
- 为普通终端 pane 增加 Markdown rendering；
- 以变量改名、机械改写或模型释义的方式转换既有实现。

## Clean-Room 角色

### 协调与合规负责人

负责人维护隔离边界，并且是需求侧与实现侧之间唯一的信息通道。职责包括：

- 维护受限 source register、人员名单、接触史和审批记录；
- 生成并校验干净源码快照；
- 审批实现团队可访问的公开标准、依赖版本和工具；
- 过滤问题与缺陷描述，避免向实现团队泄露既有实现表达；
- 保存所有问答、prompt、测试结果、构建产物哈希和审计结论；
- 在最终代码冻结前，阻止实现团队接触旧实现及其衍生资料。

### 需求团队

需求团队可以根据产品行为编写规格，但不得向实现团队提供：

- 既有源代码、diff、patch、测试代码或测试快照；
- 内部算法说明、伪代码、类型布局、函数名、变量名或注释；
- 调查报告、handoff、PR 讨论、代码评审、session transcript 或模型上下文；
- 从隔离实现直接抽取的独特 fixture、错误消息或性能 counter 名称。

需求团队提交的问题必须以输入、操作、可观察输出和资源约束表达。

### 实现团队

实现团队必须：

- 在开始前书面声明自己的相关源码、文章、演示和模型上下文接触史；
- 只使用获批源码快照、本文档的获批版本和 allowlist 中的公开资料；
- 独立选择模块边界、算法、数据结构、命名和测试实现；
- 对每项行为先建立独立测试，再实现产品代码；
- 记录每个重要设计决策的输入资料和推导过程；
- 发现可能属于隔离资料的内容时立即停止，并向协调人报告。

接触过隔离实现的人不能通过“忘记细节”、新开分支、新开聊天或重命名代码获得 clean-room 资格。

### 独立验证与审计团队

验证团队依据本文档运行黑盒、性能、安全和兼容性测试。最终相似度审计应在实现冻结后进行，审计结果不得反向成为实现提示；需要修改时，只能向实现团队返回行为级缺陷或由法务决定更换实现人员。

## 仓库与访问隔离

### 干净基线

协调人必须在受限记录中选择、验证并批准一个不含本功能的 commit。候选 commit 和相关历史不得写入发给实现团队的本文档副本。最终交付给实现团队的源码快照必须满足：

- tree 中不含本功能的产品代码、测试、vendor 修改、文档或本地证据；
- Git object database、remote refs、reflog 和工作区搜索索引不能访问隔离分支；
- 依赖 lockfile 和第三方 notices 与该基线一致；
- 导出 tree 的逐文件哈希和整体归档哈希已经保存。

推荐从获批 commit 导出源码 tree，并在隔离的新仓库中重新初始化历史。不要把包含隔离 commit object 或 remote refs 的普通 clone 交给实现团队。协调人与一名独立审查者应分别校验源码 manifest 和归档哈希，并签署交接时间、接收人及存储位置。完成后由协调人把冻结产物集成到目标分支。

### 允许资料

实现团队默认只能访问：

- 经法务批准的本文档版本；
- 经哈希校验的干净源码快照；
- CommonMark 和 GitHub Flavored Markdown 的公开规范；
- allowlist 中指定版本的 Rust、Ratatui、Crossterm 和 Markdown parser API 文档；
- 干净基线已有的构建、测试、设置、localization 和 agent lifecycle 文档；
- 协调人批准的黑盒输入、操作和预期输出。

第三方源码并非自动允许。需要阅读依赖源码时，协调人必须先记录精确来源、版本、许可证及其与隔离资料的关系。

### 禁止资料和行为

实现团队不得访问或使用：

- 既有 Markdown feature branch、publish branch、commit、PR、diff 或构建产物；
- 既有 Markdown 产品代码、测试、vendor fork、截图、日志或性能报告；
- feature handoff、调查目录、review comment、聊天 transcript、session memory 或调试日志；
- restricted source register 中列出的参考项目及其实现、文章和派生材料；
- 搜索互联网、代码索引或模型历史以寻找相同功能的实现方式；
- 通过另一名已接触人员或 AI 工具对隔离代码进行摘要、翻译、释义或重写。

### AI 工具规则

AI 辅助是否可用于实现，由法务单独批准。若允许，至少满足：

- 使用全新且受控的会话、workspace 和检索索引；
- 禁用来自污染 workspace、历史会话、memory、代码搜索或网页搜索的上下文；
- prompt 只能包含获批规格、干净基线和 allowlist 资料；
- 保存完整 prompt、响应、模型标识、工具调用和时间戳；
- 禁止要求模型复现、比较、改写或回忆任何隔离实现；
- 输出仍由具备 clean-room 资格的工程师审查和负责。

如果工具提供方无法给出足够的上下文隔离和审计能力，应禁止 AI 生成实现代码。

AI 记录必须存放在访问受控、加密且可审计的位置。协调人应在启动前确定保留期限、允许访问的角色、secret scanning、必要的隐私删减和到期删除流程；删减操作本身也必须留痕。

### 污染事故处理

任何人发现误开旧分支、旧代码搜索结果、隔离网页、受污染模型上下文或他人转述时，必须立即：

1. 停止实现和验证工作，不继续阅读或传播内容；
2. 记录人员、时间、来源、暴露范围、相关文件和后续产物；
3. 隔离暴露后产生的代码、测试、笔记、prompt 和构建产物；
4. 通知协调人与法务，由其决定废弃产物、回退到暴露前状态或更换人员；
5. 重新确认团队资格、源码快照和工具上下文后，才可恢复工作。

不得通过删除浏览记录、聊天、Git history 或本地文件来隐瞒或“修复”污染事件。

## 信息流协议

实现团队的问题使用以下格式提交：

```text
CR-Q-<序号>
相关 requirement ID：
输入和操作：
观察到的结果：
规格中不明确的行为：
需要确认的可观察结果：
```

协调人只能以 requirement clarification 或新的黑盒测试向量回答。不得提供旧实现如何工作、位于哪里或为何采用某种算法。所有问答都需要版本化；规格变更后，协调人必须重新确认它不包含隔离表达。

## 产品行为规格

### 设置契约

- 以下名称是 compatibility-required interfaces：`renderAgentMarkdown`、`--no-agent-markdown`、`agent_config_changed` 和 `render_agent_markdown`。实现不得改名，但围绕它们的内部符号必须独立设计。
- 全局 JSON setting 名为 `renderAgentMarkdown`，类型为 boolean。
- setting 缺失时默认值为 `true`。
- 显式写入 `false` 后，加载和再次序列化仍为 `false`。
- Settings > Agents 提供一个双向绑定的开关，用于控制该 setting。
- 开关默认开启，保存后无需重启应用即可生效。
- 开关具备可访问名称、说明文本和自动化标识。
- 新增字符串必须覆盖干净基线中的全部 SettingsEditor locale；pseudo-locale 遵守仓库既有策略。
- 该 setting 只控制显示方式，不参与 agent、master、helper 或 session identity 的计算。

### 内容范围

Markdown 模式只作用于 agent 生成的自然语言回复，包括：

- 当前正在显示的 streaming 回复；
- 已完成的最新回复；
- 已进入 completed-turn history 且展开显示的回复。

用户 prompt、tool 状态、错误状态、usage、welcome text 和其他 UI chrome 不因该 setting 改变语义。

### 开启 Markdown 时

实现必须提供一套 canonical rendering semantics，并让 streaming、finalized 和 history 复用相同语义。最低支持：

- paragraph 和 CommonMark soft line break；
- heading；
- emphasis 和 strong emphasis；
- ordered、unordered 和 nested list；
- block quote；
- inline code 和 fenced code block；
- link；
- GitHub Flavored Markdown table；
- strikethrough（若获批 canonical parser 的 GFM 模式支持）。

要求如下：

- Markdown 标记不应作为普通正文重复显示；
- 文本内容、顺序、Unicode scalar 和 grapheme cluster 不得丢失或重复；
- 单个换行遵守 CommonMark soft-break 语义，空行才建立新 paragraph；
- CRLF、LF、无结尾换行和空回复均可处理；
- 不完整 Markdown 是合法 streaming 输入，不得 panic、越界或隐藏已经可理解的正文；
- 后续输入改变前文语义时，下一次显示必须反映完整 canonical 结果；
- 回复完成后，显示必须与在全新进程状态下对完整原始回复执行一次 full-input render 的结果一致。
- 开启模式下 heading marker 和 fenced-code delimiter 不作为正文显示；关闭模式下仍可见。
- 每条 agent 回复保留干净基线已有的首行 marker，后续 visual row 使用与正文起始列一致的 hanging indent；空行不得重复 marker。
- wrapping 以 terminal cell width 为准，wide character 不得造成越界、错位或错误 height。

### 关闭 Markdown 时

- agent 回复按原始文本显示，`#`、`**`、backtick、fence 和 table pipe 等标记保持可见；
- 不调用 Markdown parser，也不读写仅服务于 Markdown 的衍生状态；
- 仍使用 agent pane 既有前缀、换行和宽度约束；
- 已有原始历史不被改写；重新开启后可从同一原始内容恢复 Markdown 显示。
- 继续遵守干净基线已有的通用 per-line display safety policy；若 UI 对极端长 visual row 做显式省略，完整原始内容仍须保留，且 Markdown setting 不得引入额外数据丢失。

### Theme 与样式

- 样式必须相对于 agent pane 当前前景色和背景色，不得假设固定 dark 或 light palette；
- Markdown 正文和结构样式不得写入会遮盖 pane 背景的固定背景色；
- heading、emphasis、strong、quote、code、link 和 table 应可区分，但颜色不是唯一信息载体；
- Markdown link 在本功能中是有区别样式的显示文本，不新增点击或打开行为；它可以使用 agent pane 的 ANSI palette 和 underline，但不得读取普通 terminal pane 的 profile theme 作为替代；
- light 和 dark agent pane 中正文和结构均保持可读；若系统高对比度已由干净基线传入 agent pane，本功能必须继承同一基础前景/背景且不得增加固定背景色；
- resize 或 theme 变化后，不得复用与当前显示条件不兼容的旧布局。

### Streaming 与完成态

- chunk 按接收顺序进入原始回复；结构事件与文本事件不得重排；
- reveal cursor 以 Unicode extended grapheme cluster 为单位，不能拆开 combining sequence、emoji modifier 或 ZWJ sequence；
- 同一回复的普通 append 不得造成已显示内容重复、回退或跳到其他 tab；
- source replacement、clear、finalize、tool segment 和新 agent segment 不得复用不兼容的旧 projection；
- 相同文本出现在不同 tab 或不同回复中时，不得发生跨会话状态污染；
- streaming 任意前缀都必须可单独显示；随机 chunk boundary 不得改变最终结果；
- forward reference、后补 link definition、跨 chunk table、fenced code、nested list 和 Unicode 必须在输入增长后收敛到完整 canonical 结果；
- completion 时屏幕结果必须通过 fresh full-input render 的等价性测试；持久化数据仍只能是完整原始回复。

### Terminal 与 Helper 配置传播

- helper 默认开启 Markdown rendering。
- helper bootstrap 支持 hidden option `--no-agent-markdown`；出现时初始模式为关闭。
- 关闭 setting 时，该 option 只传给 helper，不传给共享 master 或 agent CLI。
- prewarmed、stashed 后恢复和用户新打开的 helper 均遵守相同 bootstrap 规则。
- Terminal 通过既有 `agent_config_changed` 路由发送可选字段 `render_agent_markdown`，不得新增平行配置通道。
- 字段不存在时保持当前模式，不应意外关闭 Markdown。
- 字段值变化时，现有 helper 原地更新显示模式；不得重启或替换 helper、master、agent process 或 ACP session。
- runtime update 不修改已经启动进程的 command line，也不改变原始消息历史。
- setting 从 `false` 切到 `true` 再切回 `false` 时，每次都必须更新当前 pane，同时保持 tab、helper owner 和 session identity。

### Layout、Scroll 与交互

- 同一 frame 的 natural height、实际绘制、keyboard selection 和 mouse hit testing 必须基于同一批显示结果；
- Markdown 隐藏标记后，height 不能继续按原始标记字符数估算；
- resize、mode 变化、expand/collapse、selection、pane focus 和内容变化后，所有几何结果保持一致；
- manual scroll 不应被 streaming 强制跳到底部；follow-output 模式应继续显示最新内容；
- 选择较早的 completed turn 时，系统必须按需准备目标内容并保持其可见；
- action link、prompt hit region 和 completed-turn marker 必须对应屏幕上的实际行；
- 窄 pane 中 table 不能丢失 row 或 cell，也不能与前后内容重叠；
- 空 pane、极窄 pane、超长单词和 wide-character 内容不得造成 panic 或无界布局。

### 性能与资源上限

性能要求使用可测试结果表达，不规定实现算法：

- 同一状态、宽度和模式下的连续 frame 不得重新解析相同 Markdown；
- 同一 frame 不得为 height 和 render 各自重复建立完整 rendering result；
- 正常 append 的工作量应与新增内容和受其影响的局部内容相关，不应每次扫描完整历史；
- 没有变化的长历史 frame 不得遍历并 materialize 所有 completed turns；
- 屏幕绘制只 materialize viewport、有限 overscan 和交互所需的目标内容；其数量必须与总历史长度无关；
- 200 个以上 completed turns、窄 viewport、切 tab、resize 和 streaming 同时发生时，输入和 scroll 仍保持响应；
- 所有 derived display state 都必须由固定上限约束，内存占用不能随无限历史、无限回复长度或无限 tab 数持续增长；
- 实现团队在编写 retention 代码前独立提出 entry、aggregate byte、per-item 和 cross-tab 上限，由协调人根据黑盒压力目标批准并冻结；
- 超过已批准上限时必须安全地丢弃可重建状态或直接计算，不能丢失原始内容；
- derived state 的丢弃、重新计算或降级只允许影响性能，不得改变文本、样式、height 或交互结果；
- test-only instrumentation 可以统计 parse、rendering、materialization 和 history traversal，但这些 counter 的名称和内部结构由实现团队独立决定。

### 安全与隐私

Markdown 输入视为不可信数据：

- rendering 不执行 shell command、code block、HTML、script 或 embedded directive；
- rendering 不下载图片、页面、字体或其他远程资源；
- Markdown 内容不能注入未经安全处理的 terminal control sequence；
- link 的打开行为继续使用产品既有的安全和确认边界；
- 本功能自身不把 Markdown link 变为可操作控件；未来若增加该能力，必须另做安全设计和验收；
- 日志、telemetry 和性能 counter 不记录 raw prompt、raw response、Markdown source、usage、credential、account identifier 或 token；
- 错误日志只记录模式、长度、计数、版本和非敏感状态。

### 兼容性与故障恢复

- 原始 `ChatMessage` 内容和持久化格式保持不变；不得持久化 parser AST、terminal escape 或布局行；
- 缺少新 setting 或 runtime 字段的旧配置继续工作；
- 任何输入都不得让 Markdown rendering panic、终止 helper 或中断 agent session；
- 当 active response 被替换、清除、完成或由新 segment 取代时，旧的 derived display state 不得影响新内容；
- 如果独立实现选择了可失败的 parser 或 rendering API，失败时必须保留原始内容、给出不含敏感数据的诊断，并安全显示 raw text；
- build、package 和 deployment 必须使用 explicit Windows Rust target，避免打包 stale helper binary。

## 验收矩阵

以下是行为场景，不是可复制的测试实现。clean-room 团队必须独立编写 fixture、断言和辅助 API。

| ID | 场景 | 必须观察到的结果 |
| --- | --- | --- |
| CR-SET-001 | JSON key 缺失 | `renderAgentMarkdown` 为 `true` |
| CR-SET-002 | 显式保存 `false` 并重新加载 | 值仍为 `false` |
| CR-SET-003 | Settings > Agents 初次打开 | 开关存在、默认开启、可访问名称有效 |
| CR-SET-004 | UI 关闭开关并保存 | JSON 写入 `false`，当前 helper 即时更新 |
| CR-SET-005 | 检查全部 locale | 新字符串存在且非空，pseudo-locale 符合仓库策略 |
| CR-CFG-001 | 默认启动 helper | Markdown 模式开启 |
| CR-CFG-002 | 关闭模式启动 helper 与 master | option 只出现在 helper command line |
| CR-CFG-003 | prewarm、stash/restore、新开 pane | 三种路径遵守相同 setting |
| CR-CFG-004 | `false -> true -> false` runtime update | 显示即时改变，helper/master/session identity 不变 |
| CR-CFG-005 | runtime event 不含新字段 | 当前模式不变 |
| CR-RND-001 | heading、paragraph、emphasis、list、quote、link、code、table corpus | 文本和结构正确；结构 marker 不重复显示；首行 marker 与 continuation indent 对齐 |
| CR-RND-002 | 单换行与空行 | 分别遵守 soft break 与 paragraph 语义 |
| CR-RND-003 | 不完整 emphasis、fence、table 和 link | 不 panic；后续 append 后收敛到 canonical 结果 |
| CR-RND-004 | 模式关闭 | 原始标记可见，Markdown processing counter 保持零，通用长行策略不改写原始内容 |
| CR-RND-005 | 完成回复 | 最后 streaming 结果与 fresh full-input render 一致 |
| CR-RND-006 | light、dark 以及基线可提供的高对比度 agent pane | 无新增固定背景，基础前景/背景继承 agent pane，结构仍可区分 |
| CR-STR-001 | 在任意 UTF-8 byte-safe 位置随机分 chunk | 最终 text、style、height 与单次完整输入一致 |
| CR-STR-002 | combining mark、emoji modifier、ZWJ sequence | reveal 不拆分 grapheme cluster |
| CR-STR-003 | CRLF、LF、无结尾换行、空输入 | 均正确且无 panic |
| CR-STR-004 | 后补 link definition 或改变前文语义的输入 | 已显示内容按 canonical 语义更新 |
| CR-STR-005 | source replacement、clear、finalize、新 segment | 不复用过期结果，不跨 tab 污染 |
| CR-LAY-001 | 相同消息分别计算 height 和绘制 | actual line count 与 geometry 一致 |
| CR-LAY-002 | narrow/wide resize，包含 table 和 wide characters | 无丢失、重叠或 stale hit region |
| CR-LAY-003 | manual scroll、follow output、keyboard selection | viewport 行为稳定，选择目标可见 |
| CR-LAY-004 | expand/collapse completed turn | 只改变目标 turn，marker 和 action link 对齐 |
| CR-PERF-001 | 200+ turns 的 unchanged second frame | 不重新 parse/project/materialize 全历史 |
| CR-PERF-002 | 长 streaming 回复逐 chunk append | 正常增长不随完整历史长度线性恶化 |
| CR-PERF-003 | 在多个 tab 间往返 | retained state 有界，无 stale 内容或 cross-tab reuse |
| CR-PERF-004 | derived display state 达独立设计并获批的各项资源上限 | 安全丢弃或重新计算，显示结果不变，内存不再持续增长 |
| CR-SEC-001 | Markdown 含 HTML、image、script-like text、code fence | 不执行、不联网，内容安全显示 |
| CR-SEC-002 | debug/trace 日志检查 | 不含 prompt、response、Markdown source、usage 或 credential |
| CR-E2E-001 | live agent 产生多段、bold、partial syntax 和 3-column table | streaming/final 完整、可读、无重叠 |
| CR-E2E-002 | live session 中关闭再开启 setting | raw/rich 显示切换，history 和 session identity 保持 |

随机化测试至少覆盖：不同 chunk boundary、Unicode、nested list、table、fenced code、reference link、CRLF、source replacement 和无结尾换行。失败时保存 seed，不得用旧实现测试代码补齐 fixture。

## TDD 与交付流程

每个行为步骤按以下顺序完成：

1. 从获批干净基线建立最小、独立编写的失败测试；
2. 运行 focused test，记录预期 RED 原因和输出哈希；
3. 实现满足该测试的最小产品行为；
4. 立即重跑同一 focused test，记录 GREEN；
5. 运行相关 module tests、完整 WTA tests、native build 或 E2E；
6. 记录设计决策、使用的 allowlist 资料和依赖变更；
7. 由协调人确认提交不含隔离来源、旧测试或本地敏感 artifacts；
8. 再开始下一个行为步骤。

产品提交、测试提交和 clean-room evidence 的保存方式由协调人决定。实现团队不得直接向包含隔离历史的远端 fetch 或 push。

### 最低验证命令类别

- WTA explicit-target focused 和 full Rust tests；
- vendored 或新增 dependency 的独立 tests、Clippy、rustdoc 和 formatting check；
- Settings model focused build 与 round-trip test；
- Terminal SettingsEditor、TerminalApp 和 package build；
- Debug deployment 后的 Settings、bootstrap 和 live-update E2E；
- light/dark、narrow/wide、prewarmed/stashed/new helper 的人工或自动化验证；
- dependency notice、manifest、license 和 reproducibility check。

具体命令以干净基线中的仓库说明为准，不从隔离 branch 复制脚本。

## 最终审计与合并门槛

实现冻结后，协调人组织以下检查：

### 来源审计

- 每位参与者的接触史和 attestation 完整；
- 所有允许资料有版本、URL、许可证和批准记录；
- 所有需求问答、AI prompt 和工具调用可追溯；
- Git history 只来自干净快照和 clean-room 团队；
- 没有来自旧 feature branch、测试、vendor fork 或调查材料的 blob。
- dependency manifest 记录精确版本、来源 URL、archive hash、许可证、批准日期、是否允许读源码及批准人；
- vendored source modifications、generated notices、attribution 和 license compatibility 与获批 manifest 一致；
- toolchain manifest、构建环境标识、dependency source archive 和最终 artifact hash 足以复现审计结果。

### 工程审计

- 验收矩阵全部通过；
- streaming 每个增长点与 fresh full-input result 一致；
- performance counter 证明 unchanged frame、normal append 和 long history 满足有界要求；
- independently selected resource limits 通过 entry、aggregate byte、per-item 和 cross-tab 压力测试；
- 设置、localization、bootstrap、live update、raw mode 和 session identity E2E 通过；
- full WTA tests、相关 native builds 和 dependency compliance 通过。

### 独立相似度审计

只有审计团队可以在冻结后把新产物与 restricted source register 中的资料比较。至少检查：

- 长行、token sequence、注释、字符串、测试 fixture 和错误消息的精确匹配；
- 标识符、类型布局、控制流和模块拆分的非必要高度相似；
- commit 顺序、测试名称和缺陷修复顺序是否异常一致；
- 第三方许可证、NOTICE 和修改声明是否完整。

相似度工具只能提供工程证据，不能替代法务判断。发现显著相似时，不得要求实现团队仅改名或机械重写；应由法务决定接受并履行许可证、隔离并重新实现，或停止该方案。

### 合并条件

只有以下项目全部书面确认后，才能集成 clean-room 产物：

- 合规负责人确认隔离流程有效；
- 法务确认可接受的来源与许可证结论；
- 工程负责人确认验收和性能目标通过；
- 安全负责人确认不可信 Markdown 和日志边界；
- localization 和 accessibility review 完成；
- 最终 commit、dependency archive、build 和测试报告哈希已保存。

## 启动清单

| 项目 | 状态 | 负责人/证据 |
| --- | --- | --- |
| 法务批准 clean-room 流程 | 待完成 | |
| 指定协调人、需求团队、实现团队、验证团队 | 待完成 | |
| 完成人员接触史与资格审查 | 待完成 | |
| 建立受限 source register | 待完成 | |
| 审批本文档的 implementation-facing 版本 | 待完成 | |
| 选择并验证最终干净 baseline | 待完成 | |
| 生成无隔离 Git objects/refs 的源码快照 | 待完成 | |
| 建立公开标准与 dependency allowlist | 待完成 | |
| 决定 AI 工具 policy 和审计方式 | 待完成 | |
| 确定 AI 记录的访问、加密、删减、保留和删除规则 | 待完成 | |
| 建立单向需求问答渠道 | 待完成 | |
| 建立污染事故报告、隔离和恢复流程 | 待完成 | |
| 定义测试、artifact 和日志保存位置 | 待完成 | |
| 固化 toolchain、dependency archive 和 reproducible-build manifest | 待完成 | |
| 定义最终相似度与许可证审计负责人 | 待完成 | |

## Resources

- [CommonMark Specification](https://spec.commonmark.org/)
- [GitHub Flavored Markdown Specification](https://github.github.com/gfm/)
- 干净源码快照附带的 repository build、test、security 和 accessibility 文档

任何新增资源必须先进入 allowlist。本文档有意不链接或命名 restricted source register 中的实现。