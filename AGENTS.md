# Default-provider Yolo mode 开发与交接

> 本节是新 Yolo UX feature 的 dev-only 事实来源。它只记录当前产品合同、
> scope、TDD计划和worktree纪律，不进入publish branch。通用仓库说明保留在后半部分。

## Current Stage

`2026-09-04`: 用户暂停本feature开发，PM需要重新评估OpenCode选择后将Yolo toggle
强制Off并disabled（灰掉）的产品行为。不得继续修改、push或触发#828 review；PR保持
OPEN、未merge，publish local/tracking/remote及PR head为
`12536255734f950e89aff2d138b3df2ad9cb29e6`。Final exact-head Copilot review为
`5107455497`（0 new、无suppressed）；当前仅保留`TerminalPage.cpp:2100`的scope
discussion供用户review。Agent之前发布的18条`Valid finding...`回复已按用户要求删除；
Copilot原comments、18条用户`Fixed in...`总结和scope rationale均保留。除非必要，不得使用
`DinahK-2SO`账号回复线上thread。下一项独立工作从latest `origin/main`创建新的
Copilot ACP Yolo-Off investigation branches；本branch只作为暂停handoff保留。

`2026-09-03`: PR #828已创建，当前remote head是test-only
`1453262cebc6090124b65696e969b46a3a98edfc`，product parent为
`2cbe7179b83afc25db4158af08ff072d6770fa56`。Latest fetched
`origin/main@b361d91b25dda4b455a7f58ca04909c90f56bae3`仍是branch base。
Copilot review `5106424038@2cbe7179b`的16个active comments是同一有效root
cause：所有locale的`AIAgents_YoloOpenCodeWarning.Title` translator comment仍声称
InfoBar只在global Yolo On时显示。Exact-head review
`5106477200@1453262ce`生成`0 new` visible comments，但有1个有效suppressed finding：
`CurrentAcpAgent`内的`namespace Reg`未使用。Check run `100801552519`的10个spelling
annotations全部是external cspell dictionary URL 404；check为SUCCESS且没有repository
content finding，因此不修改产品或dictionary配置。

Translator-comment source selftest先准确RED `0/1`，随后16 locale comment统一到
OpenCode作为Settings default的forced-Off语义；unused alias已删除。Full ItE2E
selftests为`25/25`，16 locale XML/BOM/comment parity、Rust format、CRLF-aware diff和IDE
diagnostics clean；SettingsEditor build为0 errors。Self-contained dev review-fix已提交并
push为`08fa337ba46535052534f7d3a2bb5b27dbb48d8c`；`AGENTS.md`仍保持dev-only。
Patch-identical publish candidate是
`d9071588ac4d1f0d9744c6f7f63c7b544f590a62`，stable patch ID
`6f85a65809bf550bdc381a2835592d712905eea7`。Exact package build/deploy/launch/
freshness已通过；source fingerprint是
`D4F395F07188493BE3A7CAE815185F8D015E20A5FCD8721C9E59F3092CD4D463`，WTA SHA-256是
`63CD71CC40D4F575BB8E413F3D5369AC83C237B3B75176D3AB2A38F365168F72`。Fresh package
Yolo E2E为`6/0/1`；C292只因policy ACL未provision而跳过，其他default-provider、
outgoing-provider、OpenCode、Gemini和permission cases全部通过。下一步：refetch并require
publish remote仍是`1453262ce`、tracked state clean、candidate fast-forward且latest main
仍为ancestor；ordinary push `d9071588a`。该guard和push已成功，PR head、publish local/
tracking/remote均为`d9071588a`。16个active comments均已回复fix SHA/evidence，并确认
`Open=16`、`OpenWithOurReply=16`、`Resolved=0`。Review request脚本确认Copilot
`InFlight@d9071588a`；`copilot_work_started` event是`30515390672@20:44:39Z`。
Online checks已完成：CLA和两个spelling checks SUCCESS，三个report/update jobs按设计
SKIPPED。Exact-head `check-spelling`有0 annotations；`Check Spelling`的10个annotations
仍全部是external cspell dictionary URL 404，未指向本PR content，结论WON'T FIX。
Package cleanup确认0 worktree processes和0 backup markers。下一步：读取该work-start之后
的exact-head完整review body和suppressed sections；若review尚未提交则不重复触发，保持
in-flight并等待下一次event。不得resolve任何thread。

Exact-head Copilot review `5106704008@d9071588a`于`20:51:16Z`提交2个visible
comments、无suppressed section。Locale selftest硬编码`16`是有效fragility；
static RED找到1个hardcoded match，修复应改为与动态发现的locale directory count比较。
Resolver `scopeToDefaultProvider=false && usesSettingsDefaultProvider=false`返回现有global
值不是bug：focused test明确锁定该compatibility branch；本PR只改变default-following和
`/agent`，profile backend、saved-layout restore、historical resume及其他override owner
均是用户批准的out-of-scope。把该branch改成false会无授权改变旧行为，因此该finding应
decline with rationale并保持open。首次16条reply后GraphQL确认`Resolved=0`；之后有11条
由`DinahK-2SO`账号在并发人工作业中resolve，agent不reopen或干预。下一步：动态化locale
count、跑focused/full selftests并形成test-only review commit；reply两个新threads时继续
使用`-NoResolve`。

Locale-count static oracle从`HARDCODED_COUNT_MATCHES=1`变为`0`，dev/publish full
selftests均为`25/25`。Test-only commits为dev
`5cf9454f73e048b38fc5bb6164b2caf3a6da0ce7`和publish
`28ef341e03c8a6215cd745cb9d1f5cd10dcfbc86`；只修改
`test/e2e/selftests/ItE2E.Unit.Tests.ps1`，不改变`d9071588a` receipt的任何product/package
input。两个new threads已分别回复accepted-fix evidence和scope-based decline rationale，
均使用`-NoResolve`。Review request确认
`InFlight@28ef341e03c8a6215cd745cb9d1f5cd10dcfbc86`。下一步：等待online checks和
exact-head review，完整检查visible/suppressed comments及每个spelling annotation；任何
human-resolved thread保持原状，不reopen。

Exact-head Copilot review `5106798437@28ef341e0`于`21:02:50Z`提交1个valid
finding、无suppressed section：`AllowedAgents`或`AllowCustomAgents`把Settings default
过滤为空时，raw Yolo preference仍可能让effective getter/UI看似可用。Deterministic
SettingsModel RED在built-in policy-filtered case准确失败`0/1`。Fix让
`EffectiveAgentPaneYoloMode`基于`EffectiveAcpAgent()`并在empty时Off，同时让Settings
`CanEnableAgentPaneYoloMode`使用同一effective identity；raw preference不清除，因此agent
policy解除后仍可恢复用户选择。Focused test GREEN `1/1`；direct TAEF full
`CustomAgentAndPolicyTests`为`45/45`、exit 0；ItE2E selftests `25/25`；SettingsEditor
build 0 errors；diff和IDE diagnostics clean。下一步：提交/推送self-contained dev fix，
cherry-pick到clean publish，exact package rebuild/deploy/freshness和focused package UI
回归后再push、reply-without-resolve并请求下一轮review。

Policy-filter fix已提交并push为dev
`c4a4bf06c3689abf3b29a2b017ea449519b1caa5`，patch-identical publish candidate为
`a6ea43153fa4d8719a42ce1f2f7f4891e1bb9adb`，stable patch ID
`9fa30a7a6d0060816b72015ad2728e8a24991e5c`。Exact package build/deploy/launch/
freshness GREEN；source fingerprint是
`902DAA033426955F0EAB220D07D2E1D20D216FBFCD24CF943B22B2BCB435E53E`，WTA SHA-256是
`EFB00D566A3E5697F205E1BB4535A41D59D61F45B86D7783C5A0DDF55CD7F9D4`，171个recipe
sources一致。Fresh zero-token Yolo package suite为`6/0/1`；仅C292因policy-write
precondition未provision而skip，其他case全部通过。下一步：require publish remote仍为
`28ef341e0`、latest main ancestry和clean tracked state后ordinary-push `a6ea43153`；
该guard和push已成功，publish local/tracking/remote及PR head均为`a6ea43153`。Valid
finding已回复commit、`45/45`和package evidence并保持open；review request确认
`InFlight@a6ea43153fa4d8719a42ce1f2f7f4891e1bb9adb`。下一步：等待online checks和
exact-head review，读取visible/suppressed/spelling结果；不resolve任何thread。
Online checks现已完成：CLA和两个spelling checks SUCCESS，report/update jobs按设计
SKIPPED。`check-spelling`为0 annotations；`Check Spelling`的10个annotations仍全是
external cspell dictionary URL 404，无PR content finding。Copilot review尚在生成，不重复
触发；下一步是等待最低间隔后单次读取exact-head review。

Exact-head review `5107018834@a6ea43153`于`21:30:08Z`提交`0 new` visible
comments，但有1个valid suppressed finding：Settings Save只调用OpenCode unavailable
normalizer，未在同一write boundary清除policy-blocked Yolo，可能短暂写入policy-invalid
`true`。Source-boundary selftest准确RED `0/1`，要求两种normalizer都在
`WriteSettingsToDisk`之前；MainPage新增唯一
`ClearAgentPaneYoloModeIfPolicyBlocked()`调用后同filter GREEN `1/1`。Full selftests
`26/26`、Settings policy class `45/45`、SettingsEditor build 0 errors、diff和IDE
diagnostics clean。下一步：提交/推送dev fix，cherry-pick到publish并从exact candidate
重建/deploy/freshness、跑zero-token package regression；再push/reply-without-resolve/
request next review。

Settings Save fix已提交并push为dev
`dc4d9c37f01c353f65a0d2a40b02c5d638da7266`；patch-identical publish candidate是
`1e736f6a94478144671cebb048452c4c627275fe`，stable patch ID
`6c1fde23fc5a32b3e91a72a8f2bff9b2ee067f6c`。Exact package build/deploy/launch/
freshness GREEN；source fingerprint是
`09CD7F20AFA4BB7169573E97A6B5A2D6BFF89FF56B78DA454058BD31CA251B00`，WTA SHA-256是
`6B7CE71A6CF6D236060D350503799E8B4B850EA8DB676451F59A6E9AC8E9383E`，171个recipe
sources一致。Fresh zero-token Yolo为`6/0/1`，仍仅C292因policy-write prerequisite
skip。Guarded push已成功，publish local/tracking/remote及PR head均为`1e736f6a9`。
Suppressed finding没有可回复thread，因此未创建额外PR comment；review request确认
`InFlight@1e736f6a94478144671cebb048452c4c627275fe`。下一步：等待online checks与
exact-head review，读取visible/suppressed/spelling结果；不resolve任何thread。

Exact-head review `5107203932@1e736f6a9`于`21:55:29Z`提交`0 new` visible
comments和1个valid suppressed finding：outbound `rebind_agent`在helper接受前optimistic
把`Tab::AgentCurrentId`改成target，使mid-rebind hot Yolo update可能把target当actual。
Rebind payload已独立携带target identity/Yolo；actual identity应只来自helper status。
Identity-ownership source test准确RED `0/1`；删除唯一outbound assignment后GREEN `1/1`，
且保留status-owned assignment。Full ItE2E selftests `27/27`，LocalTests build 0 errors，
focused default/hot Yolo和rebind routing `3/3`，diff/IDE diagnostics clean。下一步：
提交/推送dev fix，cherry-pick到publish，exact package rebuild/deploy/freshness并重跑包含
outgoing-provider race的zero-token Yolo suite；然后push/request next review。

Identity fix已提交并push为dev
`621ad76eeb7859469a222b89844cd094425ba52b`；patch-identical publish candidate是
`b9d07e00215c8f0d9fb075f8b8de5e2654b901f1`，stable patch ID
`381dc5fec9e38a1c19aa56596b414997d7b51d6c`。Exact package build/deploy/launch/
freshness GREEN；source fingerprint是
`9EF71C3FE6613166BED2F4D9CDF0F42F31A7D281122299C0C0C5CA61A60FECC8`，WTA SHA-256是
`6E27286D309481A2A8F84E3F911DB8332B23DB84C8F3BDEE33D23E7FC2E9C36F`，171个recipe
sources一致。Fresh zero-token Yolo `6/0/1`，outgoing-provider race明确PASS，仍仅C292
environment skip。Guarded push已成功，publish local/tracking/remote及PR head均为
`b9d07e002`；suppressed finding无thread。Review request确认
`InFlight@b9d07e00215c8f0d9fb075f8b8de5e2654b901f1`。下一步：等待online checks和
exact-head review，读取visible/suppressed/spelling结果；不resolve任何thread。

Exact-head review `5107372007@b9d07e002`于`22:19:30Z`提交`0 new` visible
comments和1个valid suppressed documentation finding：`_EmitAgentRuntimeConfigIfChanged`
header仍把`yolo_enabled`描述成window-wide global default，实际已是按tab/current provider
resolved desired state。Static stale-wording oracle准确RED `1`；comment更新后
`STALE=0`、`CURRENT=1`，无product logic改变。下一步：提交/推送dev comment，cherry-pick
publish；为保持final-head exact source receipt仍重建/deploy/freshness，然后push/request
next review。

Comment-only commits为dev
`d8cf7c41c2fabcba6a26ecb5e7e84c93a5b9083e`和patch-identical publish candidate
`12536255734f950e89aff2d138b3df2ad9cb29e6`，stable patch ID
`2556721e780b9caa907db69a3a09336584d4037c`。Exact package build/deploy/launch/
freshness GREEN；source fingerprint是
`1DF1B10065B028D7BDF72A49CED98E16DA1545BAC4D3669A9B99F8307996F455`，WTA SHA-256是
`5BFC81ED9CE8140EB60BE669406D25B61BAAE9384216BB40066F5CD479F19AC8`，171个recipe
sources一致。因本commit仅改comment，behavioral package evidence沿用fresh parent
`b9d07e002`的`6/0/1`。Guarded push成功，publish local/tracking/remote及PR head均为
`125362557`；review request确认
`InFlight@12536255734f950e89aff2d138b3df2ad9cb29e6`。下一步：等待online checks与
exact-head review；若visible/suppressed均无新finding，运行review-loop convergence
snapshot，同时保持所有human-owned active threads unresolved。

Final exact-head review `5107455497@125362557`于`22:34:28Z`完成：39/39 files
reviewed，`Comments generated: 0 new`，无suppressed section且0 inline comments。
Exact-head checks全部SUCCESS或按设计SKIPPED；两个spelling checks中一个0 annotations，
另一个仍仅10个external dictionary URL 404，均无content finding。Official
`02-check-review-status.ps1`因其已知regex不识别当前
`Comments generated: 0 new`格式而错误输出`NoNewComments=false`；GitHub raw body校正后的
authoritative snapshot是`ReviewAtHead=true`、`NoNewComments=true`、
`SuppressedSection=false`、`InlineComments=0`、`OpenThreadsAwaitingReply=0`、
`ChecksSuccessfulOrSkipped=true`、`CorrectedConverged=true`。唯一active thread是
`TerminalPage.cpp:2100`的intentional profile/layout compatibility handoff，已有完整
decline rationale，保持unresolved供用户review。PR #828仍OPEN且未merge。

Final identities：dev local/remote
`d8cf7c41c2fabcba6a26ecb5e7e84c93a5b9083e`（仅本handoff保持tracked local
modification）；publish local/tracking/remote、PR head和registered build worktree均为
`12536255734f950e89aff2d138b3df2ad9cb29e6`；latest
`origin/main@b361d91b25dda4b455a7f58ca04909c90f56bae3`仍是ancestor。Exact package
launch cleanup后0 package processes。Automatic development/review loop完成；下一步仅为
用户审查/resolve剩余active thread并决定是否merge，agent不得merge或resolve。

`2026-09-03`: 用户已授权按本文TDD workflow进入autopilot开发。Identity gate已通过：
Copilot使用内部账号，active `gh`是社区账号`DinahK-2SO`。Primary dev是
`user/DinahK-2SO/yolo-mode-next-dev@2262cf37d`，其3个base-ahead commits只修改
本handoff；product tree仍等于`origin/main@b361d91b`。Clean publish仍是
`user/DinahK-2SO/yolo-mode-next-publish@b361d91b`。TDD support files的权威branch是
`user/DinahK-2SO/local-tdd-kit@b0942f961`。

Ownership审计结论：SettingsModel负责OpenCode effective-Off和provider notice；
SettingsEditor负责OpenCode draft clear/disabled UI；AppLogic是policy block把实际setting
写回磁盘的单一owner。`Tab`需要只为`/agent`记录scope marker，避免本PR改变明确out-of-scope
的profile/restore行为。TerminalPage使用一个pure resolver计算tab desired Yolo，并在helper
startup、agent-ready、rebind payload和targeted `agent_config_changed`中复用。WTA只在现有
rebind wire接收resolved `yolo_enabled`/policy值，更新现有YoloState并继续复用native provider
coordinator、ACK、timeout和prompt gate。下一步：先运行现有Settings/Yolo baseline；然后添加
Settings behavior、inheritance resolver和WTA rebind state的deterministic RED，不先编辑
production。

Baseline：WTA Yolo `76/76`，SettingsModel `41/41`，Terminal binding/runtime-config
focused `2/2`。RED evidence：

- `EffectiveAgentPaneYoloModeFalseForOpenCode`返回true而期望false；
  `YoloSettingsNoticeTracksSelectedProviderAndPreference`在OpenCode+Off返回None而期望
  Unavailable（Settings focused `3/5`）。
- `settings_agent_rebind_applies_resolved_yolo_before_new_session`保留旧provider的global true
  （WTA `0/1`）。
- Terminal LocalTests compile仅因缺失
  `_ResolveAutomaticYoloForAgentBinding`失败（12个同根missing-member diagnostics）。
- SettingsModel compile仅因缺失
  `ClearAgentPaneYoloModeIfPolicyBlocked`失败（2个同根missing-member diagnostics）。

下一步：实现SettingsModel/AgentRegistry/OpenCode UI/policy normalizer并立即重跑同一
Settings filters；然后实现Terminal resolver/wire和WTA rebind state。

Implementation已完成第一轮并经过两次独立review。第一轮发现OpenCode clamp可能影响
out-of-scope profile/restore以及custom provider notification遗漏；第二轮进一步发现
Settings-default/current-provider ownership、legacy OpenCode Save fallback和unavailable
OpenCode warning priority缺口。每项都先补了focused RED再修复。最终设计使用Tab上的
`/agent` scope marker和pure resolver；profile/restore在本PR保持旧行为。WTA rebind target
有generation-fenced optional wire fields，旧host缺字段时保持当前state。

Current GREEN：Settings Yolo `6/6`、SettingsModel full class `43/43`、Terminal resolver/
binding/runtime focused `4/4`、WTA Yolo `78/78`、rebind neighbors `6/6`、full WTA
`2009/0/1`，SettingsEditor/TestHost builds 0 errors，Rust format/diff/IDE diagnostics clean，
16 locale XML/BOM/comment/locked-token validation clean。Baseline package RED是OpenCode toggle
仍enabled（suite `3/1/1`）以及`/agent gemini`未产生native Off（targeted `0/1`）。
Complete TerminalApp LocalTests为`74/34/0`：34个Tab tests全部在共享
`_initializeTerminalPage`以环境错误`0x8000ffff`失败，未进入test body；本feature focused
Tab/Settings tests在独立process均通过。下一步：最终独立diff review，形成不含本文件的
publishable dev commit，复制到clean publish worktree，再从可部署layout构建exact candidate
并运行package GREEN。

Convergence review又发现并驱动了两个有效修复round。Hot Settings provider+Yolo变化不能
从previous settings推断helper实际provider；Tab现在记录master-attested/target canonical ID，
pure hot resolver覆盖outgoing、already-switched和unknown fallback。OpenCode forced clear
现在由GlobalAppSettings共享normalizer拥有，Settings lazy Save、AI Agents ViewModel、FRE、
custom deletion和internal selected-agent persistence全部复用。对应compile RED和focused
GREEN均已记录。E2E selftest Describe count RED `23/24`已修复为`24/24`。

Frozen source totals：SettingsModel `44/44`，Terminal Yolo/binding focused `6/6`，
WTA Yolo `78/78`、rebind `6/6`、full WTA `2009/0/1`，ItE2E selftests `24/24`；
SettingsEditor和TestHost builds 0 errors；16 locale XML/BOM/comment/locked-token checks、
Rust format、diff check和IDE diagnostics clean。Final independent review reports no
remaining significant issue. Next command：stage every modified publishable path except
`AGENTS.md`, commit one self-contained feature slice, then cherry-pick it into clean publish。

Publishable dev commit是`0b0048103845e993fa6ce95360b26631948529da`；patch-identical
publish commit是`2cbe7179b83afc25db4158af08ff072d6770fa56`，stable patch ID
`fb06448264100fd68dbdca6843b391b18db3a241`，两者product tree在`AGENTS.md`之外
零差异。Exact publish full WTA再次`2009/0/1`，CascadiaPackage build 0 errors。
TDD build helper首次被URL-encoded `Program Files %28x86%29` recipe source阻塞；
support branch新增behavioral RED→GREEN parser fix并push为
`user/DinahK-2SO/local-tdd-kit@a6a015edc`（BuildDeploy selftests `19/19`）。
第二次deploy遇到transient `resources.pri` user-mapped section `0x800704C8`；
Restart Manager确认locker已消失后，deploy retry成功。

Exact receipt/freshness通过：source fingerprint
`DBFBC995A4CA1DCDA3DFDBEB6A0419DE4F366BF967E07B0FB477FF4766672D11`，
WTA SHA-256 `98F30748E9642284126110F6BD8E86557C1778FC7B157AD151AEA7EA11A8CBBE`，
171个recipe source/AppX hashes一致。Package Yolo E2E `6/0/1`；仅未provision的
policy ACL case C292跳过，C291/C294/C295均在release report标为[x]。Package processes
和config backup markers均为0。下一步：refetch/guard main与remote refs，ordinary push
dev/publish，创建符合20/100/100限制的template PR，然后让online review与local broader
E2E并行。

## Branches And Worktrees

- Primary dev:
  `user/DinahK-2SO/yolo-mode-next-dev` /
  `C:\ado\intelligent-terminal-bugfix`.
- Clean publish:
  `user/DinahK-2SO/yolo-mode-next-publish` /
  `C:\ado\intelligent-terminal-yolo-next-publish`.
- Pull request: `https://github.com/microsoft/intelligent-terminal/pull/828`.
- Tracking issue: not assigned.
- TDD support:
  `user/DinahK-2SO/local-tdd-kit` /
  `C:\ado\intelligent-terminal-local-tdd-kit`.

`AGENTS.md`只属于dev worktree。Publish worktree不得包含本文件、本地harness、
真实provider prompt、raw logs、screenshots、provider homes或ignored evidence。

## Working Rules

1. 每次开始工作先更新`Current Stage`、branch/head、最新`origin/main`和下一条命令。
2. 每个独立root cause先有确定性的RED；首次production edit后立即重跑同一focused check。
3. PR修改尽可能小。除本文明确行为外，不增加provider-specific特殊处理。
4. 共用逻辑放在owning abstraction；不要把一次性判断散落在Settings、`/agent`
   和provider adapters。
5. Publish/CI测试不得调用真实模型。真实provider验证只能进入ignored本地evidence。
6. UI、安全边界或真实provider行为变化后，从exact publish candidate重新
   build/deploy并验证source、recipe、staged、installed和live identities。
7. 不得使用`Remove-AppxPackage`；不得自动登录、切换GitHub账号或修改credentials。
8. 发现相邻问题先记录并讨论，不顺手扩大scope。

## GitHub Identity Gate

每个新的Copilot session在调查、开发、build/test或线上GitHub操作前：

1. 从Copilot/VS Code账号界面确认Copilot账号以`_microsoft`结尾。
2. 运行`gh auth status --hostname github.com`和`gh api user --jq .login`。
3. Active `gh`账号必须是社区账号，且不得以`_microsoft`结尾。
4. 两个认证面分别确认；只记录账号名和时间，不记录token、cookie或account ID。
5. Session重启、账号变化或认证失败后重新执行完整门禁。

## User-visible Goal

Settings中的persisted Yolo toggle只负责**默认agent provider的自动Yolo**。
使用默认provider启动的agent panes保持现有主流程；用户通过`/agent`切换到
非默认provider时，不继承该自动设置。

这不是新的permission system：

- WTA仍只调用reviewed、provider-advertised native session capabilities。
- Provider定义的permission、sandbox、file和network效果不变。
- WTA不替用户选择ACP permission option。
- Product-owned terminal action proposals仍然需要用户确认。

## Locked Product Contract

### Persisted setting

- 保留现有key、boolean类型和默认值：

  ```json
  "agentPane.yoloMode": false
  ```

- 不增加schema migration或per-provider settings map。
- 在Copilot、Claude、Codex和Gemini之间更换Settings默认provider时，
  保留当前toggle值。
- `/agent`不修改persisted toggle。

### Settings provider matrix

| Settings default | Toggle | Persisted behavior | Message |
| --- | --- | --- | --- |
| Copilot | Enabled unless policy blocks | Preserve | No Copilot-specific Settings message |
| Claude | Enabled unless policy blocks | Preserve | None |
| Codex | Enabled unless policy blocks | Preserve | None |
| Gemini | Enabled unless policy blocks | Preserve | Info only while toggle is On |
| OpenCode | Off and disabled | Set draft to `false`; Save persists `false` | Unavailable warning |
| Custom | Existing behavior | No new special handling | No new Yolo message |

OpenCode是本feature唯一的provider-specific forced clear：

- 在Settings选择OpenCode时立即把draft设为`agentPane.yoloMode=false`。
- Toggle显示Off且不可开启；Save后磁盘值也是`false`。
- 切回其他provider仍保持Off，用户必须重新显式开启。
- Legacy `acpAgent=opencode`加`agentPane.yoloMode=true`在runtime和Settings中按Off处理。
- 打开Settings时把legacy组合规范化到draft；用户下次Save时写回`false`。
- 不能仅因application startup加载该legacy组合就后台改写用户文件。

Gemini保持conditional：

- Toggle不灰掉。
- 仅在Gemini被选中且toggle On时显示现有workspace trust信息。
- Gemini只在自己的workspace trust和provider policy允许时启用native mode。
- Intelligent Terminal不写Gemini trusted folders，也不绕过provider policy。

Custom provider不增加任何判断、disabled状态、message或capability classification。

### Group Policy

`AllowYoloMode=0`必须清除实际设置，而不只是clamp effective value：

- Toggle显示Off且disabled，并显示现有organization-policy提示。
- 内存和`settings.json`中的`agentPane.yoloMode`都设为`false`。
- 所有live sessions reconcile到native Off，包括非默认provider和手动enable的session。
- Unknown/unconfirmed disable继续fail closed。
- Policy解除后不恢复旧On值；用户必须重新开启。
- Policy blocked期间外部写入`true`不能改变runtime/UI；下一次settings write规范化为`false`。

Policy UI优先级最高；blocked时不同时显示OpenCode或Gemini notice。

### Automatic runtime inheritance

Settings-owned automatic Yolo使用一个统一规则：

```text
automatic Yolo =
    policy allows Yolo
    AND persisted toggle is On
    AND current session provider ID equals the Settings default provider ID
```

- 按canonical provider ID比较；model变化不改变provider identity。
- Host和WSL中的同一canonical provider视为同一个provider。
- 每个新ACP session仍必须独立advertise并ACK exact native capability。
- Provider discovery、restore、generation fencing、timeouts和fail-closed逻辑继续由
  现有native Yolo coordinator拥有。

### `/agent`

- 切到canonical ID不同于Settings默认值的provider时，主动reconcile native Off；
  不能只是不发送On。
- Off达到known-safe结果之前不释放prompt gate。
- 切到Settings默认provider时，应用persisted toggle并等待native ACK。
- 只切model不改变Yolo inheritance。
- Host/WSL同provider保留inheritance，但新session仍需fresh capability和ACK。
- Provider-owned manual `/config`保持session-scoped，不修改Settings toggle。
- Copilot ACP permission regression继续只在runtime处理；Settings不增加version UI。

### Existing tabs after Settings default changes

- Default-following tabs保持现有行为：retire旧ACP session并rebind/recreate到新默认provider。
- `/agent` override tabs保留当前provider。
- 对这些override tabs重新计算automatic Yolo：
  - provider现在等于新默认值时，继承persisted toggle；
  - provider不再等于默认值时，主动reconcile native Off。
- 对应operation settle前保持prompt gate。

## English UI Copy

### Toggle

- Header:
  `Use Yolo mode for the default agent provider`
- Help:
  `Requests Yolo mode when an agent pane starts with the default provider. The provider defines which confirmations, sandbox restrictions, file access, and network access change. Switching providers in an agent pane does not turn Yolo mode on for a non-default provider.`

### OpenCode

- Title:
  `Yolo mode isn't available for OpenCode`
- Message:
  `OpenCode doesn't provide a supported Yolo mode, so this setting is turned off and unavailable.`
- Severity保持`Warning`；InfoBar不可关闭。
- 只要Settings默认provider是OpenCode就显示，用于解释disabled toggle。

### Gemini

- 保留title:
  `Gemini Yolo mode depends on workspace trust`
- 保留message:
  `Gemini enables Yolo mode only when its workspace trust and provider policy allow it.`
- Severity保持`Informational`；InfoBar不可关闭。
- 仅Gemini加toggle On时显示。

### Policy

复用现有标准message：
`This setting is managed by your organization.`

不为Copilot临时upstream defect或custom provider增加Settings copy。

## Scope

### In scope

- Toggle header/help copy。
- OpenCode forced-Off/disabled行为和warning。
- Gemini现有conditional info行为。
- `AllowYoloMode`清除实际stored setting。
- `/agent`的default-provider-scoped automatic Yolo。
- Settings默认provider变化时重新计算现有`/agent` override tabs。
- 对应focused tests、localization和exact-package validation。

### Out of scope

- Custom provider特殊处理。
- 将inheritance规则接入profile `agentPaneBackend`、saved-layout restore、
  historical-session resume或其他非`/agent` override来源。
- Provider-owned trusted-folder UX或配置写入。
- 新provider mapping、provider negotiation或WTA-owned `/yolo`。
- ACP permission selection或terminal-action confirmation改变。
- Copilot permission regression的Settings UI。
- JSON key重命名或per-provider persistence。
- 不相关的Yolo、sandbox或COM authorization工作。

Publish文档只描述已实现的default-provider和`/agent`合同，不发布future gap列表。

## Modularization And Ownership

不要在`OnAgentSwitchRequested`中内联一组特殊判断。创建一个小型、无副作用、
可复用的inheritance decision abstraction，输入：

- persisted Yolo preference；
- policy state；
- Settings default provider ID；
- current binding/provider ID。

它只返回Settings-owned automatic desired state。当前PR仅连接Settings/default
launch/rebind和`/agent`路径；未来其他入口可直接复用。

| Area | Owner |
| --- | --- |
| Settings toggle/provider notices | `TerminalSettingsEditor/AIAgentsViewModel.*` |
| Built-in provider UI metadata | `src/cascadia/inc/AgentRegistry.h` |
| Persisted setting/policy model | `TerminalSettingsModel/GlobalAppSettings.*` |
| Policy read/watch/hot reload | `src/cascadia/inc/AgentPolicy.h`, TerminalApp watcher |
| Tab binding/default provider/`/agent` | `TerminalApp/TerminalPage.cpp`, `Tab.h` |
| Runtime config wire | agent-ready config, `agent_config_changed`, rebind payload |
| Runtime desired state/prompt gates | `tools/wta/src/app_contracts/yolo.rs`, `app.rs`, `app_events.rs` |
| Native provider transition | `tools/wta/src/protocol/acp/native_yolo.rs` |
| Settings resources | `TerminalSettingsEditor/Resources/**/Resources.resw` |

Host决定Settings preference是否适用于某个tab；Rust coordinator决定exact provider
session如何到达并ACK该状态。

## TDD Plan

Production edit之前为每个独立root cause建立deterministic RED：

1. **Settings**
   - Supported provider change保留toggle。
   - OpenCode清除draft并disabled。
   - Legacy OpenCode+On在Settings Save规范化，不在startup后台写。
   - Gemini保持enabled且只在On时显示info。
   - Custom行为不变。
   - Policy block清除实际stored value。
2. **Inheritance decision**
   - Default provider继承On；non-default为Off。
   - Canonical ID忽略model和Host/WSL source。
   - Policy始终为Off。
3. **`/agent` lifecycle**
   - Default到non-default在first prompt前完成disable。
   - Non-default到default等待enable ACK。
   - Failed/unknown disable保持prompt gate。
   - Manual provider config不写persisted toggle。
4. **Hot Settings default**
   - Default-following tabs按现有行为rebind。
   - `/agent` override tabs保留provider但双向重新计算Yolo。
5. **Policy**
   - Startup/live block持久化`agentPane.yoloMode=false`。
   - 所有live sessions Off；解除policy不恢复On。
6. **UI/localization**
   - Header/help、OpenCode disabled/message、Gemini conditional info和policy优先级。
   - 所有real/pseudo locales key parity；只翻译`<value>`，`<comment>`与en-US一致。

首次实现edit后立即运行同一RED selector。Focused GREEN后才运行neighboring/full suites。

## Validation Gates

- SettingsModel focused tests：persistence、policy、provider notice matrix。
- TerminalApp LocalTests：binding/default-provider和`/agent` routing。
- Focused WTA Yolo/agent-switch tests，使用deterministic ACP barriers，不用sleep。
- Full explicit-target WTA：

  ```powershell
  cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
  ```

- C++/XAML/resource改动后的SettingsEditor和TerminalApp builds。
- 所有修改`.resw`的XML/BOM/EOL/comment/key-parity检查。
- Publishable zero-token Settings加deterministic ACP `/agent` package E2E。
- Policy package case仅在provisioned机器运行；缺少policy-write ACL记为`BLOCKED`。
- Real-provider acceptance如有需要只能local/ignored，不能进入`test/e2e`或CI。
- Exact publish candidate build/deploy/freshness。
- Dev/publish产品tree在本文件和ignored evidence之外必须一致。

## Publish Discipline

- 只在`C:\ado\intelligent-terminal-bugfix`开发和维护本handoff。
- `C:\ado\intelligent-terminal-yolo-next-publish`保持clean，直到自包含commit通过review。
- 只复制publishable commits；不得复制本文件或本地evidence。
- Focused/full source validation与exact-package build/deploy/freshness达到可信状态后
  可以push；broader local E2E在PR创建后与online review并行。
- 未经明确授权不得rewrite inherited history或force-push。
- `origin/main`前进时，final package evidence前先audit并integrate。

## PR Creation And Review Workflow

### Push confidence gate

当publish branch达到足够可信状态后，不必等待全部broader local E2E完成：

1. Require clean tracked publish state and current audited `origin/main` ancestry.
2. Require no `AGENTS.md`、local harness、real-provider prompt、raw evidence或其他
   dev-only path进入publish diff。
3. Require deterministic RED-to-GREEN、focused/neighboring tests、full relevant source
   suites和format/diff checks通过。
4. Require exact publish candidate build/deploy/freshness通过，测试binary与candidate
   HEAD一致。
5. 使用ordinary push发布publish branch；不得force-push。

### PR metadata

Push后创建PR并保留`.github/PULL_REQUEST_TEMPLATE.md`的结构：

- PR title不得超过20个words。
- `## Summary of the Pull Request`不得超过100个words。
- `## Validation Steps Performed`不得超过100个words。
- 其他sections没有适用内容时可以留空；如填写，必须尽量concise且准确。
- 不得把尚未运行、blocked或失败的validation写成PASS。
- PR body只描述publish中实际实现的behavior，不公开dev-only future gap列表。

### Parallel online review and local E2E

PR创建后立即并行推进：

- Online checks、Copilot review和其他reviewers在published HEAD上运行。
- 本地从同一exact published HEAD运行broader package/UI/real-provider E2E。
- 检查spelling workflow的conclusion、annotations和相关log summary；绿色check也可能
  包含需要判断的content annotations。
- 每次publish HEAD变化后，重新确认线上review/check对应的SHA；需要新package
  evidence时从新HEAD重建。
- Local E2E发现的问题先记录、分类并构造deterministic RED，再决定是否修复。

### Critical review triage

持续monitor线上checks、reviews和所有active comments。Review inventory必须同时包含：

- 所有visible inline/file-level comments和active threads。
- Copilot每个相关review object的完整body，包括suppressed comment/finding sections。
- Review summary中的generated/suppressed counts；`0` visible comments不能证明没有
  suppressed finding。
- Spelling check的全部annotations，而不只是check conclusion。

对每条visible、suppressed或spelling finding独立判断：

1. 核对comment针对的exact SHA、代码路径和当前实现。
2. 用现有contract、可复现behavior、tests和安全边界验证其claim。
3. 分类为valid fix、duplicate/already addressed、out of scope或incorrect，并在
   dev-only handoff记录理由和证据。
4. Valid finding先建立deterministic RED，再做最小fix、验证并push新的publish commit。
5. 不因为comment来自自动reviewer就直接接受，也不因为后续代码碰巧改变相关行就
   直接忽略。

Spelling findings必须区分repository content问题与external dictionary/network、
generated-file或workflow infrastructure warning。优先修正文案；不要未经项目惯例
支持就添加dictionary allowlist或宽泛ignore pattern。

### User-owned merge and comment resolution

- Agent不得把PR merge到`main`。
- Agent不得resolve、dismiss、close或以其他方式关闭任何active review
  comment/thread。
- 即使某条comment已在后续iteration修复、变成duplicate或代码行变为outdated，
  也必须保持其active状态，供用户亲自review和resolve。
- 不得调用GraphQL、REST、CLI或UI操作修改active thread的resolution state。
- 使用review-loop脚本时，所有reply必须保持`-NoResolve`语义；不得运行会resolve
  thread的模式，也不得运行outdated-thread cleanup。
- 可以实现并push必要fix，也可以在需要时留下包含commit SHA和证据的reply，
  但reply不能resolve thread。
- Review loop的完成条件不是`open threads = 0`。当current HEAD已有review、
  checks settled、所有comments均完成critical triage且valid fixes已push后即可停止；
  active comments继续保留给用户。
- PR merge和active comment resolution均由用户最终执行。

## Completion Checklist

- [x] Product behavior和minimal scope已确认。
- [x] Dev/publish worktrees来自同一`origin/main`。
- [x] 旧feature branch、review、evidence和test进度已从当前handoff清除。
- [x] 每个root cause有deterministic RED。
- [x] Owning abstractions中的minimal implementation完成。
- [x] Settings、policy、`/agent`和prompt-gate focused suites GREEN。
- [x] 修改的locales全部通过结构和语义验证。
- [x] Full WTA及相关C++ builds/tests GREEN。
- [x] Pre-push exact publish candidate build/deploy/freshness GREEN。
- [x] Dev/publish product trees和commit slices验证完成。
- [x] Publish中没有dev-only artifact或real-provider prompt。
- [x] Publish branch ordinary-pushed并创建符合word limits和template的PR。
- [x] Online review/checks与同HEAD local E2E并行完成。
- [x] Publishable zero-token package E2E与所需local-only E2E GREEN或明确BLOCKED。
- [x] Visible、file-level和suppressed review findings全部完成critical triage。
- [x] Spelling conclusion、annotations和相关warnings全部完成critical triage。
- [x] 所有valid review/spelling fixes已验证并push。
- [x] 所有active comments保持unresolved，等待用户review。
- [x] PR未被agent merge到`main`。


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
- **Session MCP** exposes `run_command_in_current_shell`, `create_workspace`,
  `delegate_task_in_new_workspace`, and `request_user_input`.
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
