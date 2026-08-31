---
author: Clean-room requirements team (待指定)
created on: 2026-08-31
last updated: 2026-08-31
issue id: N/A
status: Draft
---

# Streaming Markdown Package Clean-Room 规范

## 文档目的

本文档定义一个通用、开源的 streaming Markdown package 的 clean-room 开发与交付要求。该 package 接收持续增长的 Markdown 文本，在不重复处理已确认稳定内容的前提下，增量完成解析和 Ratatui rendering，并始终与相同输入的完整单次 rendering 保持一致。

首选交付方式是向 `tui-markdown` 上游贡献该能力。如果上游不接受相关 scope，则从同一份 clean-room 实现发布一个公开、可独立使用的开源 package。Intelligent Terminal 只是首个 consumer，不拥有 package 的 Markdown streaming 算法。

本文档及其他 clean-room requirements、协调记录和内部 review 文档可以使用中文，implementation team 可以直接使用经批准的中文版本。**所有产品与公开 deliverables 必须使用英文**，包括 source code identifiers、comments、tests、fixtures、API documentation、README、issue、RFC、pull request、commit message、changelog、release notes、benchmark report、security policy、license/compliance records，以及 Intelligent Terminal product documentation。

本文档不是法律意见，也不证明 clean-room 已经成立。法务或开源合规负责人必须在实现开始前批准流程、人员、允许资料和发布方式。

## 规范覆盖索引

| Requirement area | 本文档章节 |
| --- | --- |
| Clean-room implementation | [Clean-Room 边界](#clean-room-边界)、[Clean-Room TDD 流程](#clean-room-tdd-流程) |
| Target changes to `tui-markdown` | [对 `tui-markdown` 的要求](#对-tui-markdown-的要求) |
| Upstream-first route | [上游贡献路线](#上游贡献路线) |
| Open-source fallback publication | [上游不接受时的开源发布路线](#上游不接受时的开源发布路线) |
| Package input contract | [输入 contract](#输入-contract) |
| Package output contract | [输出 contract](#输出-contract) |
| Calling modes | [调用模式](#调用模式) |
| Monotonic processed position and traceback | [增量进度与回溯要求](#增量进度与回溯要求) |
| Tables, fences, inline syntax and global rewrites | [必须处理的特殊情况](#必须处理的特殊情况) |
| Finalization and resource limits | [Finish 与 malformed input](#finish-与-malformed-input)、[Resource limits 与 backpressure](#resource-limits-与-backpressure) |
| Intelligent Terminal integration | [Intelligent Terminal 集成](#intelligent-terminal-集成) |
| English product and public deliverables | [产品与公开 Deliverables（全部英文）](#产品与公开-deliverables全部英文) |

clean-room 团队产生的实现是唯一产品实现。上游 PR、fallback package 和 Intelligent Terminal integration 必须消费同一份实现历史，不得分别开发或相互翻译两套算法。

## 目标

package 必须提供以下能力：

- 接收按顺序到达的有效 UTF-8 Markdown chunks；
- 保存或接收当前 authoritative source，并支持 append、replace、clear 和 finish 生命周期；
- 只重新解析和重新 rendering 可能被新输入影响的区域；
- 对尚未闭合或可能被后续输入重新解释的尾部保持可替换状态；
- 返回当前完整 Ratatui styled output，并指出输出从哪里开始可能发生变化；
- 对可安全永久输出的行提供明确边界，供 direct-output consumer 选择使用；
- 在任意 chunk 边界、任意中间前缀和完成态下保持确定性；
- 完成态与相同 options 下的 fresh full-input render 完全一致；
- 支持多个相互隔离的并发 stream instance，不使用进程级可变单例状态；
- 对 derived state、table layout 和可选 syntax highlighting 设置资源上限；
- 保留现有 batch API 的兼容性和 Markdown semantics。

## 非目标

第一版不负责：

- host event protocol 或 provider-specific event decoding；
- Intelligent Terminal 的 tab、process 或 conversation lifecycle；
- network chunk coalescing 和 frame scheduling；
- typewriter animation 或 reveal cadence；
- host response marker、application chrome、scroll、selection 或 mouse hit testing；
- transcript persistence 或 completed-turn history cache；
- 执行 Markdown 中的 code、HTML、script、image 或 remote resource；
- provider-specific Markdown repair；
- 通过改写既有隔离代码产生“新”实现。

## Clean-Room 边界

### 角色

至少设立以下相互分离的角色：

- **协调与合规负责人**：维护 source register、人员接触史、资料 allowlist、问题过滤、证据保管和发布审批。
- **需求团队**：只提供本文档及后续获批的行为澄清，不提供参考实现代码、diff、测试或内部结构。
- **实现团队**：从获批的官方 `tui-markdown` 干净基线独立设计和实现。
- **验证团队**：根据黑盒要求、公开规范和独立 fixtures 验证 correctness、performance 和 compatibility。
- **最终审计团队**：在实现冻结后进行来源、相似度、依赖和许可证审计。

接触过受限参考实现、现有 Intelligent Terminal streaming Markdown 实现、现有本地 vendor customization、调查源码或其详细派生资料的人员，不应加入 clean-room 实现团队。新开 branch、workspace、chat 或重命名代码不能恢复 clean-room 资格。

### 允许资料

实现团队默认只能访问：

- 法务批准的本文档 implementation-facing 版本；该版本可以使用中文；
- 官方 `tui-markdown` 仓库中获批 commit 的干净快照和公开历史；
- CommonMark 与 GitHub Flavored Markdown 公开规范；
- allowlist 中指定版本的 Rust、Ratatui 和获批 Markdown parser 文档；
- `tui-markdown` 当前公开 API、贡献说明和测试约定；
- 协调人批准的、独立编写的黑盒输入与预期输出；
- 为 fallback package 批准的开源发布和供应链工具文档。

阅读第三方 dependency source 必须事先记录精确版本、URL、archive hash、许可证、批准日期和允许用途。

### 禁止资料

实现团队不得访问或使用：

- 现有 Intelligent Terminal Markdown feature branch、代码、测试、commit、PR、vendor tree 或构建产物；
- 现有本地 `tui-markdown` customization branch、source-metadata patch 或其测试；
- 调查目录、handoff、review discussion、chat transcript、assistant memory、截图、日志或性能报告；
- restricted source register 中列出的其他 streaming Markdown 实现及其文章、issue、代码或衍生材料；
- 由已接触人员或 AI 对上述资料所作的摘要、翻译、伪代码、重写或实现建议；
- 互联网或代码索引中以寻找同类内部算法为目的的搜索。

### AI 工具

只有在法务批准后才可使用 AI 生成实现。若允许，必须使用隔离的 workspace、会话、检索索引和 memory；prompt 只能包含获批规格、干净基线及 allowlist 资料。完整 prompt、response、model identifier、tool call 和时间戳必须进入受控审计记录。无法证明上下文隔离时，不得使用 AI 生成产品代码或测试。

### 污染事故

发现误读隔离资料时必须立即停止，记录人员、时间、来源和影响范围，隔离暴露后产生的代码、测试、笔记、prompt 与构建产物，并由法务决定废弃、回退或更换人员。不得通过删除记录或机械改写来处理污染。

## 交付架构

```text
ordered visible Markdown chunks
            |
            v
+---------------------------------------+
| Open-source streaming Markdown package|
|                                       |
| source lifecycle                      |
| incremental parse + render            |
| affected-region traceback             |
| current styled snapshot               |
| stable-output metadata                |
| bounded derived state                 |
+---------------------------------------+
            |
            v
Ratatui Text + update metadata
            |
            v
host-specific prefix / viewport / scroll / interaction
```

package 负责 Markdown correctness 和增量 rendering。host 负责决定何时把一个 chunk 变为 user-visible input，以及如何把 package output 放入应用布局。

## 对 `tui-markdown` 的要求

### 保持现有 batch contract

- 现有 batch rendering entry points 保持 source compatible，除非上游 maintainer 明确批准 breaking release。
- 现有 `StyleSheet`、image fallback、parser extension 和 optional highlighting semantics 继续适用。
- streaming 与 batch 必须共享同一个 canonical Markdown semantics；不得维护一套独立 grammar 或第二套 finalized renderer。
- 不启用 streaming 的 consumer 不应承担新的 runtime、I/O、thread 或 large dependency 成本。
- 新能力应是 opt-in public API；是否使用 Cargo feature 由上游设计评审决定。

### 新增 stateful stream contract

新增一个 consumer-owned state object。每个 object 只代表一个 Markdown document lineage，并提供以下概念操作；最终英文 API 名称由 clean-room 实现团队提出并经上游 review，不由本文档规定：

| 概念操作 | 输入 | 结果 |
| --- | --- | --- |
| Create | rendering options、初始 context、resource limits | 空 stream state |
| Append | 一个非空或空的有效 UTF-8 chunk | 当前 output update |
| Replace | 一个完整的有效 UTF-8 source | 丢弃不兼容 derived state 后的 output update |
| Clear | 无 | 空 source 和空 output |
| Update context | width、styles/theme revision 或 terminal capability | 新 context 下的 output update |
| Current | 无 | 当前 source 对应的完整 styled snapshot |
| Finish | 无或 final context | canonical final snapshot；可选择消费 stream state |
| Inspect | 无 | 非敏感 counters、resource usage 和 fallback reason |

要求：

- mutating call 不要求 consumer 再次传入此前全部 chunks；
- Current 应允许借用 package-owned output，避免每次 frame clone 整个 document；
- output 的有效期和下一次 mutation 的关系必须由 Rust type system 或清晰 API contract 保证；
- Replace 必须处理 source shrink、同长度不同内容和完全不相关的新 document；
- empty Append 是 idempotent no-op；重复读取 Current 不得触发 parsing 或 rendering；
- 多个 object 可交错调用而不共享可变 document state；
- package 不直接写 stdout，不生成 ANSI stream，不执行 I/O，也不拥有 application event loop。

### 输入 contract

- 每次 API 调用接收有效 UTF-8；transport 若在 code point 中间切分 bytes，host 必须先完成 decoding。
- chunk 可以在 grapheme cluster、Markdown delimiter、line ending 或任何 block/inline construct 中间结束。
- source 必须按原样保留；rendering 不修改、repair、trim、truncate 或规范化 authoritative source。
- line endings、trailing spaces、leading blank lines、NUL-like visible content 和无结尾 newline 的语义必须确定。
- parser options、style context、width policy 和 feature selection 必须成为 output compatibility 的一部分。
- package 必须支持 append lineage；Replace、Clear 或 Finish 后的复用规则必须明确。

### 输出 contract

每次 mutation 后，consumer 至少能够获得：

- 与当前完整 source 对应的 Ratatui `Text` 或等价 styled text snapshot；
- 当前 output 中最早可能发生变化的 logical/visual row 位置；
- 当前 output 中可被视为稳定、不再因普通 append 改变的前缀长度；
- 本次是否发生 full recomputation、bounded fallback 或 context-only reflow 的非敏感状态；
- 可选的 source-to-output mapping，供 selection 或 diagnostics 使用，但 host 不应依赖 package 内部解析策略。

这些是语义字段，最终 public identifiers 必须由 clean-room 团队用英文独立设计。

对于 retained UI，consumer 可以从最早变化行开始替换旧 suffix，也可以直接使用完整 snapshot。对于不可回写 stdout 的 consumer，只能永久提交 package 明确标记为稳定的行；其余 tail 必须保留为可替换显示或延后输出。

### Canonical parity

对任意有效 input prefix，在相同 options 和 context 下：

```text
incremental current snapshot == fresh batch render of the complete current prefix
```

相等至少包括：

- line 和 span 数量；
- visible text；
- style、modifier 和 link metadata；
- table cell 顺序与边框；
- source consumption；
- wrapping 后的 row count 和 display width；
- malformed/unfinished construct 的 fallback。

Finish 的结果必须与 final source 的 fresh batch render 完全一致。incremental state 永远只是优化，不能成为独立的 semantic source of truth。

## 增量进度与回溯要求

本规范要求实现维护两个不同的概念，但不规定其 public 或 private identifiers：

- **已确认前缀的结束位置**：其之前的 source 和 output 已满足稳定性证明，在同一个普通 append lineage 内只能保持或向前推进。
- **本次更新最早受影响的位置**：新输入可能改变其后的解释；它可以在尚未确认的尾部中向前回退，以覆盖需要重新分类或重新 layout 的 construct。

通常，本次更新最早受影响的位置不能早于已确认前缀。若 enabled syntax 或 document-wide definition 确实可能改变已确认前缀，则原稳定性假设失效：实现必须结束或重置该 lineage，对完整 document 重新计算，并在重新建立证明前不再承诺旧稳定边界。不得悄悄修改已经向不可回写 consumer 声明为永久稳定的 rows。

### 已确认前缀

实现必须维护一个 source position，使其之前的内容在普通 append 下无需重复 parsing 和 rendering。本文档不规定该 position 的变量名、类型名、容器或计算代码，但要求：

- position 使用原始 UTF-8 source 的 byte offset，并且始终位于有效 character boundary；
- 在同一个 append lineage 中，已确认 position 只能保持或向前推进；
- position 只能推进到 parser-confirmed 的 top-level structural boundary；
- position 之前的 rendered prefix 必须与 fresh full-input render 的对应 prefix 相同；
- ordinary append 的 parser 和 renderer 不得再次读取 position 之前的 source；
- active top-level construct 及任何仍可能被后续输入重新分类的相邻 construct 必须留在可变区域；
- nested construct 的结束不能单独证明 enclosing top-level construct 已稳定；
- 无法证明安全时，必须更保守地少推进，而不是猜测更靠后的边界；
- correctness boundary 不能仅由 blank-line、regular expression 或 line-prefix scanner 决定；scanner 只能用于快速拒绝或要求更多回溯。

### 回溯

新 chunk 到达后，package 必须找出最早可能被重新解释的 source position 和对应 output row，并从那里替换 output。一般规则是：

- 从当前可变 top-level construct 的开始处重新处理；
- 如果新输入可把前一个 construct 重新分类或合并，则回到该前一个 construct 的开始处；
- 如果 document-wide construct 可改变更早输出，则回到 document 开始；
- 已经向 consumer 声明为稳定的 output 不得在普通 append 中被修改；若某项 enabled syntax 无法满足这一点，就必须在更早阶段保留更多 mutable output；
- Replace、source shrink、parser-option change 或无法验证的 source mapping 可以重置整个 lineage；
- width 或 theme change 可以重新 layout/style 全部 output，但不应无故重新 parse source semantics。

实现可以采用 persistent parser state、局部重放、block cache 或其他独立设计，只要满足上述可观察结果和复杂度要求。

### 性能可验证性

package 必须提供 test-only 或非敏感 diagnostics，使验证团队能够证明：

- 对大量已完成 top-level blocks 后追加短尾部时，已确认前缀不会再次 parsing 或 rendering；
- 对相同 source 重复读取 output 时，处理量为零或常数级 bookkeeping；
- traceback 的工作量只覆盖最早受影响位置之后的内容，除非触发 document-wide recomputation；
- source replacement 和 global invalidation 的 full recomputation 可被明确观察；
- diagnostics 不记录或导出 raw Markdown content。

## 必须处理的特殊情况

本节来自对多种已公开实现所暴露问题的行为归纳。implementation-facing 英文版本不得列出这些实现的名称、仓库或内部 identifiers。

### Table

Table 是必须显式处理的回溯场景：

- 一行普通文字可能在后续 delimiter/alignment row 到达后被重新解释为 table header；此时必须回到候选 header 开始处重新 parsing 和 rendering。
- delimiter row 可能跨多个 chunks；在确认前，候选 header 和 delimiter 都不能被永久标记为稳定。
- 未完成 row、缺少可选 outer pipe、escaped pipe、code span 中的 pipe、empty cell 和 uneven cell count 不得导致 panic 或 silent data loss。
- 新 row 可能扩大某一 column 的 preferred width，因此整个 table 的边框、所有 column positions 和所有 rows 都可能变化；output replacement 必须从 table 开始处发生。
- alignment markers、inline styles、links、wide characters、combining marks 和 emoji 必须参与正确的 cell measurement。
- table 后出现明确的非 table top-level content或 Finish 之前，package 必须保守判断 table tail 是否仍可扩展。
- supplied width 足够时使用正常 table semantics；宽度不足时必须采用有界且无 overflow 的策略。允许的策略包括收缩 columns、wrap cells 或转换为保持 row/cell 关系的 stacked representation，但 streaming 与 batch 必须一致。
- table 的 measured height 必须来自实际返回的同一批 rows。
- 对不可回写 consumer，仍可能被新 row 改变的 table rows 不得被声明为稳定。

### Paragraph 与 heading ambiguity

- 持续增长的 paragraph 在 top-level 结束被确认前保持 mutable。
- 单个 newline 是 CommonMark soft break，不自动形成 paragraph boundary。
- 后续 underline-like line 可能把前一 paragraph line 重新分类为 heading；必须回到前一相关 block。
- trailing spaces、backslash 和随后到达的 newline 可能改变 soft/hard break 语义。
- heading marker、closing marker 和 attributes 被拆分时，不得显示重复 marker 或丢失正文。

### List、quote 与 rule ambiguity

- ordered/unordered/task-list marker 可跨 chunks 形成；marker 未完成时保留有用文本并保持 tail mutable。
- lazy continuation、indentation 和 blank line 可能改变 list nesting、item continuation 或 tight/loose layout；必要时回到 enclosing list 开始处。
- 新 item 可能改变整个 list 的 spacing；此前相关 rows 必须可替换。
- blockquote marker、nested quote 和 lazy continuation 被拆分时保持 source 顺序。
- delimiter-like line 可能在 thematic rule、list item、heading underline 或其他 block 之间产生歧义；由 canonical parser 决定，不能由简单 scanner 提前冻结。

### Fenced 与 indented code

- opening fence、language/info string 和 closing fence 都可能跨 chunks。
- open fence 在未完成时必须安全显示为 code-like 或 deterministic literal fallback，不能等待结束而永久隐藏全部 body。
- closer-like text 只有满足 canonical fence 规则时才结束 block；不同 marker、长度不足或 indentation 不符时仍属于 body。
- 新 chunk 关闭 fence 后，必须从 opening fence 或更早受影响位置重新 rendering，确保 fence marker、language label 和 body style 正确。
- indented code、相邻 paragraph 和 blank line 的分类变化必须由 canonical parser 处理。
- code body 的文字和 whitespace 必须保持；无 trailing newline 也不能丢失最后内容。
- syntax highlighting 是 optional presentation layer，不得决定 Markdown correctness。
- unknown language、malformed info string、oversized block、highlighter failure、stale async result 或 unsupported terminal capability 必须回退到 plain code output。
- 如果 highlighting 异步执行，结果必须匹配当前 source、range、language 和 theme revision；过期结果不得应用。

### Inline constructs

以下 construct 必须支持任意 chunk 分割和 deterministic incomplete-state behavior：

- emphasis、strong emphasis 和 strikethrough；
- inline code，包括不同长度的 backtick delimiter；
- inline link、reference link、autolink、destination 和 optional title；
- image label/destination 及 deterministic text fallback；
- escape sequence 和 HTML entity；
- footnote、citation-like text 和 task marker；
- adjacent styled spans、multiple spaces、long URL 和 nonbreaking token。

未闭合 construct 不得 panic，也不能把全部已接收正文永久隐藏。后续 closing input 可以重新 rendering mutable tail。跨 wrapped rows 时 style 和 link metadata 必须连续，不能通过 whitespace normalization 重建 source。

Citation 或 provider extension 只有在 canonical parser 或显式 extension API 支持时才能获得特殊 semantics；否则安全显示为普通文字。

### Reference 与 document-wide rewrite

- reference definition、footnote definition或任何 enabled extension 的 document-wide definition 可能改变此前出现的 label/reference output。
- 一旦发现这类 construct，必须重新计算当前完整 document，或采用能证明相同结果的等价机制。
- 在无法证明后续 append 不会继续改变早先 output 时，不得继续向 consumer 承诺新的永久稳定行。
- 对不可回写 consumer，包含 unresolved reference-like label 的 rows 必须保持非永久状态，直到 Finish，或 package 能证明后续 definition 不会改变这些 rows。retained UI 可以在 definition 到达后从真实最早变化处替换此前 output。
- 插件或 extension 必须声明自己是否可能重写先前 output；未知 extension 按可能全局影响处理。
- regular expression 或 line scanner 不能作为 document-wide construct 的 authoritative detector。

### HTML、metadata、math 与扩展 block

- HTML block、inline HTML、comment、metadata/front matter、math-like block、diagram-like block 和 reasoning-like extension 必须由 enabled canonical semantics 处理，或确定性降级为 literal text。
- opener/closer 或 comment terminator 跨 chunks 时，相关 tail 保持 mutable。
- partial HTML/comment 不得破坏随后普通 Markdown 的恢复。
- package 不执行 HTML、script、diagram、math、reasoning directive 或 embedded command，也不发起网络访问。

### Unicode、UTF-8 与 line endings

- source offsets 始终指向原始 UTF-8 bytes，不得指向 code point 中间。
- chunks 可以在 extended grapheme cluster 中间结束；后续 combining mark、emoji modifier、regional indicator 或 ZWJ sequence 到达时，受影响的最后 output row 必须可替换。
- wrapping 不得拆开 extended grapheme cluster。
- display width 必须正确处理 CJK、emoji、combining mark、zero-width joiner 和选定的 ambiguous-width policy。
- `\r` 与随后 chunk 的 `\n` 必须形成正确 CRLF semantics；source mapping 仍对应原始 bytes。
- LF、CRLF、mixed endings、leading/trailing blank lines 和无 trailing newline 都必须覆盖。
- parser normalization 若导致 mapping 无法证明正确，必须退化为安全 full-input rendering。

### Non-text ordering barrier

package 不解释 tool、permission、error、notification 或其他 transcript events，但必须提供让 host 在插入这些事件前取得当前确定 snapshot 的操作。host 负责保证先到达的 text 在后续 non-text event 前可见，并在 document 完成时调用 Finish。package 不应接收 ANSI、already-rendered rows 或 application event objects。

### Finish 与 malformed input

- Finish 不得依赖 synthetic newline，除非该行为是显式 option 且 batch API 使用相同 option。
- unclosed fence、link、emphasis、HTML、list、quote、entity 或 code span 必须产生 deterministic visible output。
- 所有已接收 source bytes 必须保留；昂贵 rendering 可以降级，但不能修改 authoritative source。
- final output 必须经过 fresh full-input parity validation，而不是直接信任 incremental fragments。
- parser 或 highlighter 失败时，返回 bounded、non-sensitive diagnostic，并安全回退到 plain styled text；不能使 host process 崩溃。

### Width、theme 与 reflow

- semantic parsing 与 width/theme presentation 应具有独立 invalidation behavior；resize 或 theme change 不应重复 parsing unchanged source。
- supplied width 改变后，所有受影响 rows、table geometry、style spans 和 height 必须重新计算并返回正确 change metadata。
- 每个 visual row 必须适合 supplied width，或使用 documented bounded fallback。
- default foreground/background 跟随 consumer-provided `StyleSheet`；core package 不假设 dark theme，不硬编码 white foreground 或 opaque background。
- theme 或 highlighting theme change 后，旧 styled/highlighted output 不得继续复用。

### Resource limits 与 backpressure

- 在实现任何 retention 或 cache 之前，协调人必须批准一份英文 **Resource Budget Decision Record**。该记录至少冻结 per-document、aggregate、per-item、table 和 highlighting work limits，以及目标 workload、测量环境和超限 fallback。数值必须由 clean-room 团队根据公开 target constraints 与独立 benchmark 提出，不得从隔离实现的常量推导。
- authoritative source 与 derived state 分别计量；derived overhead 不能无界增长。
- cache 至少具有 total-byte 和 per-document 上限；存在多 entry cache 时还必须有 entry-count 上限。
- table layout 具有 row、cell、column 和 byte budget；highlighting 具有 source byte、line 和 time/work budget。
- 超限时丢弃可重建 state 或使用 documented plain fallback，correctness 不变。
- stale background result 被丢弃，不得覆盖更新后的 source。
- package 不负责 network backpressure；host 可以 coalesce bursts，但 package 对每个实际提交的 prefix 都必须正确。
- diagnostics 可以报告 bytes processed、rows replaced、full recomputation、cache usage 和 fallback category，但不得包含 raw source。

## 调用模式

以下仅描述概念性调用；名称不是最终 API identifiers。最终英文 API proposal 由 clean-room 实现团队提交。

### Retained UI

```text
create one stream state for one visible response

for each ordered, user-visible chunk:
    append the chunk
    obtain the current snapshot and earliest changed row
    replace the host rows from that point

on resize or theme change:
    update the rendering context
    replace rows reported as affected

on completion:
    finish the stream
    verify/use the canonical final snapshot
    persist the raw source in the host transcript
```

Intelligent Terminal 应为每个 active response 持有独立 package object，不得使用 thread-local global document cache。它继续负责 ordered text-event handling、raw history、grapheme-safe reveal scheduling、settings、pane-specific style source、message marker、viewport、scroll、selection 和 mouse geometry。

如果 reveal scheduler 暂时只显示完整 source 的前缀，只有变为 visible 的 grapheme-safe text 才 Append 到 package；尚未显示的 network backlog 留在 host。若显示前缀被替换或缩短，使用 Replace，而不是伪造反向 Append。

Markdown setting 关闭时，Intelligent Terminal 直接显示 raw visible source，不调用 package parser。重新开启时，对当前 visible source 执行一次 Replace 或创建新 stream object，之后继续 Append。切换不能重启 host/provider process 或改变 conversation identity。

### Irreversible output

```text
append a chunk
obtain the current snapshot and stable-prefix row count
permanently emit only newly stable rows
keep the remaining tail replaceable or delayed
finish and emit the canonical remainder
```

此模式不能把仍可能受 table widening、open block、inline closure 或 global definition 影响的 rows 提前写入不可修改 scrollback。

### Batch/history rendering

已完成历史可以继续使用 canonical batch API。若 consumer 保留 Finish 返回的 owned final snapshot，也可以缓存该 snapshot，但 resize、style、theme 或 width change 后必须按 package contract 更新或重新 rendering。raw Markdown 仍是持久 source of truth。

## Intelligent Terminal 集成

拿到已发布 package 后，Intelligent Terminal 应：

1. 用公开 registry version 和 lockfile checksum 引用 package；临时 alpha 只能引用公开 repository 的 immutable commit/tag，并需供应链审批。
2. 删除本地 vendored customization 和 host Rust UI layer 中的 streaming Markdown parsing、source-boundary tracking、partial recomputation 及相应 global cache。
3. 保留 application-specific event ordering、reveal scheduling、raw mode、settings propagation、layout、history retention 和 interaction logic。
4. 为每个 active response 建立独立 stream object，把 ordered visible chunks 交给 package。
5. 把 consumer-provided body width 和 pane-relative `StyleSheet` 作为 rendering context；package 返回 body rows 后，host 再添加 agent marker 或 application chrome。
6. 让 natural height、actual drawing、selection 和 hit testing 消费同一 package snapshot。
7. Finish 后将 raw source 存入现有 transcript message storage contract；不持久化 parser state、ANSI 或 Ratatui rows。
8. Markdown disabled mode 完全绕过 package；runtime toggle 不改变 host/provider process 或 conversation identity。
9. 更新 dependency manifest、lockfile、SBOM/NOTICE generation 和第三方许可证记录。
10. 用 package differential tests 加上 Intelligent Terminal E2E 验证 streaming、finalized、history、resize、theme、toggle 和 long-history behavior。

## 上游贡献路线

### 并行而非串行

上游沟通和实现可以并行，但只能维护一份 clean-room 产品代码：

```text
one clean implementation branch
        |                    |
        v                    v
upstream issue/PR       public prerelease for integration
```

不等待 maintainer 回复才开始实现，也不分别开发“上游版”和“自有版”。所有实现 commit 必须能够以小型、可 review 的顺序提交上游。

### 建议的英文 deliverables

1. **Design issue / RFC**：说明 use cases、package boundary、input/output contract、canonical parity、stable progress、traceback、tables、resource limits 和 non-goals。
2. **Behavior and differential test PR**：建立独立 fixtures、random chunking 和 batch-parity harness；测试不得来自隔离实现。
3. **Minimal internal-enablement PR**：只暴露 streaming 实现真正需要、且 maintainer 同意的 canonical renderer hooks；不要预设现有本地 patch 的 API。
4. **Stateful streaming API PR**：加入 consumer-owned state、append/replace/clear/finish、snapshot/update metadata 和 bounded fallback。
5. **Documentation and benchmark PR**：公开 API examples、compatibility、performance evidence、limitations 和 migration notes。

maintainer 可以要求合并或重新拆分 PR，但 clean-room 代码来源和测试独立性不能改变。

### 上游接受标准

只有在以下条件满足后，Intelligent Terminal 才切换到正式上游 release：

- API 和 semantics 已由 maintainer 接受；
- release 包含所需功能和 tests；
- crates.io artifact、repository tag 和 source hash 一致；
- version、license、MSRV 和 dependency policy 满足 Intelligent Terminal 要求；
- package tests、docs、Clippy、format、benchmarks 和 security review 通过；
- Intelligent Terminal lockfile 与 compliance metadata 已更新。

## 上游不接受时的开源发布路线

### 决策顺序

1. 如果官方 `tui-markdown` public API 足以实现 streaming，优先发布一个依赖官方 crate 的 companion package。
2. 如果必须访问或修改 canonical renderer internals，发布一个公开、明确标注来源和差异的 forked package。
3. 不在 Intelligent Terminal 仓库内继续维护私有 vendor patch 作为长期方案。

### Companion package

companion package 应：

- 使用唯一且不暗示官方归属的 crates.io package name；
- 依赖明确兼容范围内的官方 `tui-markdown` release；
- 只拥有 streaming state、incremental orchestration、update metadata 和 bounded derived state；
- 通过 differential tests 证明 output 与依赖的 batch renderer 一致；
- 在 upstream API 足够时避免复制 renderer source；
- 记录兼容的 upstream version matrix。

### Forked package

若必须 fork：

- 从法务批准的官方干净 baseline 创建公开 repository；
- 更改 package name，避免冒充官方 `tui-markdown`；
- 保留原项目的 copyright、MIT/Apache-2.0 license files 和适用 notices；
- 在英文 README 中明确说明这是独立维护的 fork、fork baseline、主要差异和 upstream relationship；
- 将通用改动保持为可上游的 commits，定期合入 upstream security 和 correctness fixes；
- 不携带任何受限参考实现的代码、测试、注释或 identifiers；
- 对 vendor 或修改后的 dependency 生成完整 provenance 和 license records。

### 公开发布要求

无论 companion 还是 fork，都必须开源并至少提供以下英文 deliverables：

- public source repository；
- 法务批准的 OSI-compatible license files，以及所有继承的 copyright/notices；为保持与上游兼容和后续可贡献性，默认采用与上游一致的 `MIT OR Apache-2.0` dual-license，除非法务书面批准其他选择；
- English README、API docs、examples、CHANGELOG、CONTRIBUTING 和 SECURITY policy；
- public issue tracker；
- reproducible Cargo.lock 或适用的 dependency manifest；
- CI：format、Clippy、all-features/no-default-features tests、rustdoc、MSRV 和主要 target build；
- differential/property/fuzz tests 与 benchmark results；
- crates.io release 或其他经批准的公开 Rust registry release；
- immutable Git tag、source archive hash、crate checksum 和 release notes；
- 至少两名组织控制下的 package owners，避免单人发布风险；
- vulnerability intake、release signing/provenance 和 dependency update policy；
- deprecation 与迁移策略：若上游以后接受等价能力，发布迁移版本并在合理窗口后停止 fork-specific API。

紧急集成可以使用公开 repository 的 immutable revision 或公开 prerelease，但不能引用个人机器 path、私有不可审计 artifact 或可移动 branch。正式产品版本应优先使用公开 registry artifact。

## 测试要求

### Differential correctness

对独立 corpus 的每一个 append point：

- incremental current output 等于 fresh batch render；
- Finish 等于 final fresh batch render；
- random chunking 不改变任何中间 prefix 的 canonical result；
- Replace、Clear、context change 和多 stream 交错不会复用错误 state；
- earliest changed row 不晚于真实最早变化处；
- stable row prefix 在未来普通 append 中绝不变化；
- raw source 与调用输入逐 byte 相同。

corpus 至少覆盖：

- headings、paragraphs、soft/hard breaks 和 rules；
- ordered、unordered、nested、task 和 loose/tight lists；
- nested blockquotes；
- GFM tables，包括 candidate header、split delimiter、column widening、escaped pipes、inline styles、empty/uneven cells 和 wide characters；
- fenced/indented code、split opener/closer、unknown language、无 trailing newline 和 oversized block；
- emphasis、strong、strikethrough、variable-length code spans、links、images、entities、escapes、footnotes 和 references；
- global definitions 出现在 references 之前或之后；
- HTML/comment、metadata、math-like 和 unsupported extension fallback；
- LF、CRLF、mixed endings；
- CJK、emoji、ZWJ、combining marks、flags 和 grapheme split；
- malformed/unclosed constructs；
- source shrink、same-length replacement、unrelated replacement 和 empty source；
- width/theme/highlighting context changes。

### Complexity and pointer evidence

测试或 benchmark 必须证明：

- 大量稳定 top-level content 后追加小 tail 时，不重新 parsing/rendering 已确认 prefix；
- 一直增长的单个 paragraph、table、list 或 code block 可以保持 mutable，即使这意味着重新处理该 active construct；
- table column widening 从 table 开始更新 output，而不是仅追加新 row；
- paragraph-to-heading、candidate-header-to-table、list looseness 和 fence closure 等重新分类会回到足够早的位置；
- document-wide definition 会触发完整 recomputation 或经证明等价的机制；
- unchanged Current 不产生重复 work；
- memory overhead 和 fallback 符合冻结的 limits；
- diagnostics 不暴露 Markdown source。

### Robustness and security

- arbitrary chunk sequence 不 panic、不越界、不产生 invalid UTF-8；
- fuzz/property tests 覆盖 Append、Replace、Clear、Finish 和 context changes 的随机序列；
- Markdown 不执行 embedded code/HTML/script，不下载 resource；
- control characters 经过 Ratatui/host 的获批安全策略；
- parser/highlighter failure 安全回退；
- stale async work 不覆盖新 revision；
- logs、errors 和 metrics 不包含 raw source、prompt、credential 或 account data。

### Intelligent Terminal integration

- default-on setting、disabled raw path、bootstrap 和 live update；
- host/provider process 与 conversation identity 在 toggle 前后不变；
- pending、finalized 和 history 使用相同 package semantics；
- grapheme-safe reveal 与 package Append 配合；
- table/Unicode 在 narrow/wide pane 中无 overflow 或 geometry mismatch；
- resize/theme change 不重新 parse unchanged source；
- natural height、render、selection 和 mouse geometry 使用同一 snapshot；
- long history 与多个 tabs 不产生 cross-stream state contamination；
- package dependency、NOTICE/SBOM 和 deployment artifact 是预期版本。

## Clean-Room TDD 流程

每个 behavior change 按以下顺序：

1. clean-room 实现团队根据英文规格独立编写最小 failing test；
2. 运行 focused test 并记录预期 RED；
3. 实现最小 GREEN，不阅读隔离资料；
4. 立即重跑相同 test；
5. 运行相关 differential、property、full crate 和 documentation tests；
6. 更新英文 API docs、decision record 和 evidence；
7. 由协调人检查资料来源、dependency、artifact 和 Git history；
8. 再开始下一项 behavior。

可以并行的工作包括：上游 design discussion、clean implementation、independent test corpus、fallback release automation 和 Intelligent Terminal adapter prototype。不能并行维护两份不同 streaming algorithm，也不能让 adapter prototype重新实现 package behavior。

## 产品与公开 Deliverables（全部英文）

### 必须交付

- Approved implementation-facing requirements specification（可使用中文，并作为内部 clean-room evidence 保存）；
- clean-room participant attestations and access log；
- approved source/dependency allowlist and restricted source register；
- source snapshot manifest and hashes；
- upstream design issue/RFC and pull requests；
- streaming API source code, tests, docs and examples；
- differential/property/fuzz test corpus；
- benchmark and resource-limit report；
- approved Resource Budget Decision Record；
- security and privacy review；
- license, attribution, SBOM/provenance and dependency records；
- Intelligent Terminal integration PR and E2E evidence；
- final source-similarity and provenance audit；
- release artifact, immutable tag, checksums and release notes；
- fallback public repository/package materials when upstream delivery is unavailable。

### 不得进入产品与公开交付

- 未经批准的内部 planning 草稿；已批准的中文 clean-room requirements 可以进入受控 evidence archive，但不随公开 package artifact 发布；
- 受限项目名称、链接、commit 或源码片段；
- 旧 Intelligent Terminal implementation、tests 或 vendor patch；
- 调查笔记、chat transcript、local paths、credentials、private logs 或 ignored artifacts；
- 未经批准的 AI-generated code 或 tests。

## 合并与发布门槛

只有以下条件全部满足后才可用于 Intelligent Terminal 产品版本：

- 法务或开源合规确认 clean-room 流程和许可证处理有效；
- 上游 release 或 fallback public package 已从冻结源码可复现构建；
- package correctness、pointer efficiency、traceback、resource bounds 和 security tests 通过；
- API 文档和 SemVer policy 完整；
- Intelligent Terminal 已删除对应本地 streaming parsing/rendering 逻辑；
- package version/checksum、lockfile、NOTICE/SBOM 和 build artifact 一致；
- full host Rust tests、相关 native builds 和 live E2E 通过；
- 独立审计没有发现未解决的来源或显著表达相似性问题；
- 所有产品与公开 deliverables 已使用英文并完成 review；内部 clean-room requirements 和协调记录可以保留中文。

## 启动清单

| 项目 | 状态 | 负责人/证据 |
| --- | --- | --- |
| 法务批准 package clean-room 流程 | 待完成 | |
| 指定五类角色及人员 | 待完成 | |
| 完成人员接触史与资格审查 | 待完成 | |
| 建立 restricted source register | 待完成 | |
| 批准 implementation-facing 规格（可使用中文） | 待完成 | |
| 选择官方 `tui-markdown` 干净 baseline | 待完成 | |
| 生成并双人校验源码 manifest/hash | 待完成 | |
| 建立 standards/dependency/tool allowlist | 待完成 | |
| 决定 AI policy 与审计保留方式 | 待完成 | |
| 建立单向需求问答渠道 | 待完成 | |
| 批准英文 package v1 scope 与 Resource Budget Decision Record | 待完成 | |
| 提交英文 upstream design issue | 待完成 | |
| 建立公开 fallback repository 和 release automation | 待完成 | |
| 建立独立 differential/fuzz corpus | 待完成 | |
| 确定 crates.io/registry owners 与 security contact | 待完成 | |
| 确定 Intelligent Terminal adapter owner | 待完成 | |
| 确定最终相似度、许可证和供应链审计人 | 待完成 | |

## Public Standards

- [CommonMark Specification](https://spec.commonmark.org/)
- [GitHub Flavored Markdown Specification](https://github.github.com/gfm/)
- [The Cargo Book: Publishing on crates.io](https://doc.rust-lang.org/cargo/reference/publishing.html)
- [Semantic Versioning 2.0.0](https://semver.org/)

任何新增 implementation resource 必须先进入 allowlist。restricted source register 中的实现不得出现在 implementation-facing 副本中。
