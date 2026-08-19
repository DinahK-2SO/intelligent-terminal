# Feature TDD 开发与交接模板

> 本文件用于新 feature、行为变更和回归修复的 test-driven development、发布验证与交接。
> 产品行为、已提交测试和可复现证据始终是最终事实来源。

## 使用前必读

复制或开始使用本模板时，先完成以下操作：

1. 替换所有 `<PLACEHOLDER>`。可用 `rg -n '<[A-Z0-9_]+>' AGENTS.md` 检查遗漏。
2. 补充所有标记为 `[必填]` 的章节；不适用的 `[可选]` 章节应删除，而不是保留空壳。
3. 将示例命令、测试名、路径、branch、remote、package、binary 和 hash 改为当前 feature 的真实值。
4. 在开发过程中持续更新 `Current Stage`、验证结果、review triage 和 evidence inventory；不要只在结束时补写。
5. UI、渲染或交互变更必须保留 RED/GREEN 截图和最终真实用户流程截图。纯后端变更可删除截图条款，但必须说明替代的可观察证据。
6. 涉及真实 agent、云服务、硬件或其他外部依赖时，保留相应的真实集成验收章节；否则删除该条件章节。

### Placeholder 清单

- `[必填]` `<FEATURE_NAME>`、`<FEATURE_SUMMARY>`、`<USER_VISIBLE_GOAL>`、`<OUT_OF_SCOPE>`
- `[必填]` `<BASE_COMMIT>`、`<DEV_BRANCH>`、`<DEV_REMOTE>`、`<PUBLISH_BRANCH>`、`<PUBLISH_REMOTE>`、`<ISSUE_OR_PR>`
- `[必填]` `<OWNING_CODE_PATH>`、`<OWNING_ABSTRACTION>`、`<NEAREST_TEST>`、`<FOCUSED_TEST_COMMAND>`、`<FULL_TEST_COMMAND>`
- `[必填]` `<RED_ORACLE>`、`<EXPECTED_FAILURE>`、`<GREEN_ORACLE>`、`<INVARIANTS>`、`<GUARDRAILS>`
- `[按需]` `<E2E_SUITE>`、`<E2E_COMMAND>`、`<FIXTURE>`、`<PACKAGE_NAME>`、`<BINARY_PATHS>`、`<DEPLOY_COMMAND>`
- `[按需]` `<EVIDENCE_ROOT>`、`<SCREENSHOT_MATRIX>`、`<REAL_INTEGRATION>`、`<REVIEW_EVIDENCE_DIR>`
- `[持续更新]` `<CURRENT_STAGE>`、`<PUBLISHABLE_COMMIT>`、`<PUBLISH_HEAD>`、`<VALIDATION_RESULTS>`、`<OPEN_ITEMS>`

## Feature Metadata

- Feature: `<FEATURE_NAME>`
- Summary: `<FEATURE_SUMMARY>`
- User-visible goal: `<USER_VISIBLE_GOAL>`
- Base: `<BASE_COMMIT>`
- Dev branch: `<DEV_BRANCH>` -> `<DEV_REMOTE>`
- Publish branch: `<PUBLISH_BRANCH>` -> `<PUBLISH_REMOTE>`
- Issue / pull request: `<ISSUE_OR_PR>`
- Evidence root: `<EVIDENCE_ROOT>`
- Current publishable commit: `<PUBLISHABLE_COMMIT>`
- Current publish head: `<PUBLISH_HEAD>`
- Out of scope: `<OUT_OF_SCOPE>`

## Current Stage

`<DATE>`: `<CURRENT_STAGE>`

记录当前处于 RED、实现、focused GREEN、full validation、exact publish validation、
真实集成验收或 review follow-up 中的哪一步。包含阻塞项和下一条可执行命令。

## Scope And Contract

### User-Visible Contract

- `<USER_VISIBLE_BEHAVIOR_1>`
- `<USER_VISIBLE_BEHAVIOR_2>`
- `<ERROR_OR_EDGE_BEHAVIOR>`
- `<ACCESSIBILITY_OR_INPUT_BEHAVIOR>`
- `<PERFORMANCE_OR_LIFECYCLE_BEHAVIOR>`

每条 contract 都必须能映射到至少一个自动化断言或人工可观察证据。不要只描述内部状态。

### Preserved Invariants

- `<INVARIANTS>`
- 未涉及的输入方式、已有 workflow、设置迁移和兼容行为保持不变。
- 不扩大 feature 的 ownership boundary，不顺手修复无关问题。

### Guardrails

- `<GUARDRAILS>`
- 不通过测试专用 product path、硬编码 fixture 输出或不可达状态满足验收。
- 不以内部字段变化代替真实输出或用户流程验证。
- 只格式化 touched files，避免 repository-wide mechanical churn。

## Ownership Hypothesis

```text
<USER_OR_SYSTEM_INPUT>
  -> <ENTRY_POINT>
  -> <STATE_OR_DOMAIN_OWNER>
  -> <RENDER_OR_OUTPUT_OWNER>
  -> <OBSERVABLE_RESULT>
```

- Owning code path: `<OWNING_CODE_PATH>`
- Owning abstraction: `<OWNING_ABSTRACTION>`
- Falsifiable hypothesis: `<HYPOTHESIS>`
- Cheapest discriminating check: `<CHEAPEST_CHECK>`
- Nearest existing test / fixture / helper: `<NEAREST_TEST>`

在首次 product edit 前必须能够写出上述 hypothesis 和 check。若 check 不能区分候选原因，
只补一次邻近读取或测试，然后选择最小可逆 edit；不要无限扩展调查范围。

## Commit And Worktree Discipline

- Publishable changes先在 dev branch 形成一个自包含 commit：product code、自然归属的
  unit/integration tests、确定性 fixture、已有 E2E framework 内的 regression case，
  以及应随产品发布的 checklist 或 test metadata。
- Dev-only changes单独提交：本交接、进度记录、ignored screenshots/reports/logs、
  本地 orchestration、provider 配置、实验，以及不应进入 publish 的最终验收 harness。
- Publish worktree 只直接 cherry-pick publishable commit。不要 cherry-pick mixed commit
  后再 restore 文件，也不要把 dev-only acceptance commit 带入 publish。
- 不修改或回退无关的用户改动。若无关改动不阻塞当前工作，保持原状。
- 不 force-add ignored evidence。需要提交 review evidence 时，复制最终选定文件到
  `<REVIEW_EVIDENCE_DIR>`。
- 未经明确要求，不创建额外 branch、不重写历史、不使用 destructive git command。

## Test Reuse And Framework Boundaries

- 首先复用或扩展 `<NEAREST_TEST>`、`<FIXTURE>` 和 `<E2E_SUITE>`。
- 新增测试应落在 ownership 最近的现有 suite 中，并只引入使 regression 稳定所需的
  最小 helper 或 deterministic fixture。
- 当现有 framework 无法执行真实用户操作时，可在 dev-only 范围建立模块化 local
  orchestration 以取得 RED/GREEN evidence，并将通用 framework 提取作为独立 PR。
- 不在 feature commit 中夹带大型 test framework、通用 harness rewrite 或无关基础设施。
- Mock/deterministic fixture 可用于 focused RED/GREEN、几何、路由和故障隔离；若 contract
  依赖真实外部系统，它不能替代最终真实集成验收。

## Reproduction And RED Oracle

### Baseline Identity

- Source commit: `<BASE_COMMIT>`
- Build command: `<BASELINE_BUILD_COMMAND>`
- Package / deployment: `<PACKAGE_NAME>` / `<DEPLOY_COMMAND>`
- Relevant binaries: `<BINARY_PATHS>`
- Source/deployed hashes: `<BASELINE_HASHES>`

### Reproduction

1. 从 exact baseline build 并部署，记录 commit、package path、binary size 和 SHA-256。
2. 使用 `<FIXTURE_OR_REAL_INPUT>` 建立最小场景，并验证 setup preconditions。
3. 通过真实 entry point 执行 `<USER_ACTION>`。
4. 捕获实际输出、日志、测试报告；UI 变更同时保存 RED screenshot。
5. 证明失败只发生在 `<RED_ORACLE>`，而不是 setup、连接、fixture 或错误 binary。

- RED oracle: `<RED_ORACLE>`
- Expected failure location/message: `<EXPECTED_FAILURE>`
- Setup evidence: `<RED_SETUP_EVIDENCE>`
- RED artifact paths: `<RED_ARTIFACTS>`

如果 baseline 不能在预期 oracle 上失败，停止 product edit，先报告现有行为和证据。

## Strict TDD Workflow

1. 找到最近的 existing test、fixture、helper 和 E2E suite。
2. build/deploy exact baseline，并记录 binary identity。
3. 只运行新 case，确认它按 `<EXPECTED_FAILURE>` RED。
4. 添加 ownership 最近的最小 unit/state/render regression，并确认 RED。
5. 在 `<OWNING_ABSTRACTION>` 做最小实现。
6. 首次 substantive edit 后立即运行 `<FOCUSED_TEST_COMMAND>`；不要先扩大改动范围。
7. 若失败支持 hypothesis，修复同一 slice 并重复 focused check；若 falsify hypothesis，
   只向真正 owner 邻近移动一步。
8. focused GREEN 后运行 neighboring tests、`<FULL_TEST_COMMAND>` 和 required build。
9. 运行 `<E2E_COMMAND>`，从真实入口验证 `<GREEN_ORACLE>`。
10. 提交 publishable commit；将 dev-only evidence/orchestration 另作 commit。
11. clean publish worktree 直接 cherry-pick publishable commit。
12. 从 exact publish HEAD build/deploy，校验 source/deployed binary SHA-256，并重跑 E2E。
13. 若依赖 `<REAL_INTEGRATION>`，最后从 dev-only harness 对 exact publish package 执行真实集成验收。
14. 对 UI/渲染/交互变更捕获该轮 exact publish HEAD 的 fresh success screenshots 并逐图检查。
15. 更新本文件的 stage、validation、review triage、artifact inventory 和 open items。
16. 先 push dev 并确认同步，再 push 已验证的 publish HEAD；记录两个 remote head。

## Implementation Record

- Behavioral change: `<IMPLEMENTATION_SUMMARY>`
- State / API changes: `<STATE_OR_API_CHANGES>`
- Preserved invariants: `<INVARIANTS>`
- Performance implications: `<PERFORMANCE_IMPLICATIONS>`
- Security / privacy implications: `<SECURITY_IMPLICATIONS>`
- Rejected alternatives and rationale: `<REJECTED_ALTERNATIVES>`

记录最终实现的事实，不保留已经失效的设计猜测。若 ownership hypothesis 被证伪，更新
Ownership Hypothesis 并说明哪个 check 改变了判断。

## Validation Matrix

| Layer | Command / Method | Expected | Result | Evidence |
|---|---|---|---|---|
| Focused RED | `<FOCUSED_RED_COMMAND>` | `<EXPECTED_FAILURE>` | `<RESULT>` | `<PATH_OR_LOG>` |
| Focused GREEN | `<FOCUSED_TEST_COMMAND>` | `<GREEN_ORACLE>` | `<RESULT>` | `<PATH_OR_LOG>` |
| Neighboring tests | `<NEIGHBOR_TEST_COMMAND>` | No regression | `<RESULT>` | `<PATH_OR_LOG>` |
| Full relevant suite | `<FULL_TEST_COMMAND>` | All pass | `<RESULT>` | `<PATH_OR_LOG>` |
| Explicit build | `<BUILD_COMMAND>` | 0 errors | `<RESULT>` | `<PATH_OR_LOG>` |
| Packaged / deployed E2E | `<E2E_COMMAND>` | `<GREEN_ORACLE>` | `<RESULT>` | `<PATH_OR_LOG>` |
| Static analysis | `<STATIC_ANALYSIS_COMMAND>` | `<EXPECTED>` | `<RESULT>` | `<PATH_OR_LOG>` |
| Real integration `[可选]` | `<REAL_INTEGRATION_COMMAND>` | User workflow passes | `<RESULT>` | `<PATH_OR_LOG>` |

### Exact Publish Identity

- Publish commit: `<PUBLISH_HEAD>`
- Package identity/path: `<PACKAGE_IDENTITY_AND_PATH>`
- Source binaries and SHA-256: `<SOURCE_BINARY_HASHES>`
- Deployed/live binaries and SHA-256: `<DEPLOYED_BINARY_HASHES>`
- Identity conclusion: `<HASH_MATCH_RESULT>`

测试 source 可以来自 dev-only harness，但被测 app/package 必须来自 exact publish HEAD。
显式设置 package selector，避免 harness 自动选择 Store、Release 或其他已安装版本。

## Real Integration Acceptance `[可选]`

仅在 feature 涉及 agent、云服务、硬件、认证 provider 或其他真实依赖时保留本节。

- Integration/provider: `<REAL_INTEGRATION>`
- Version/model when observable: `<INTEGRATION_VERSION>`
- Preconditions: 已安装、已认证、通过正常 product settings 选择；不记录 secret。
- Workflow: 启动 exact publish package，连接真实依赖，提交唯一且无害的输入，等待真实结果，
  执行 `<USER_ACTION>`，并断言 product-owned state/output。
- Forbidden substitutes: mock/custom command、replay、injected completed state、fake provider。
- Result and evidence: `<REAL_INTEGRATION_RESULT_AND_ARTIFACTS>`

无法运行真实验收时，workflow 状态是 blocked，而不是 complete 或 skipped。

## Visual Evidence `[UI/渲染/交互变更必填]`

- Screenshot matrix: `<SCREENSHOT_MATRIX>`
- Required states: failing baseline、before action、after action、recovery/edge states。
- Required provenance: exact publish commit、package path、source/deployed hashes、capture command。
- Required inspection: product UI 非空且可辨识；目标状态可见；layout 稳定；无 overlap、clipping、
  透明/全黑帧、错误窗口、启动占位画面或 mock 内容冒充真实验收。
- Automated checks: 在可行时加入 target HWND、nonblack pixel、dimensions 和 distinct-frame checks；
  自动检查不能替代逐图人工检查。
- Latest evidence directory: `<LATEST_SCREENSHOT_DIR>`

每轮触及同一 user-visible path 的修复都要重新截图。不得用旧截图加新测试报告代替本轮证据。

## Review Triage

Current review status: `<REVIEW_STATUS>`

Open review items: `<OPEN_ITEMS>`

每轮 review 追加一条记录：

- Date / review ID / head SHA: `<REVIEW_ITERATION>`
- Finding path and summary: `<FINDING>`
- Decision: `<ACCEPT_DECLINE_ESCALATE>`
- Technical rationale: `<RATIONALE>`
- RED evidence: `<REVIEW_RED_EVIDENCE>`
- Fix or response: `<RESOLUTION>`
- GREEN validation: `<REVIEW_GREEN_EVIDENCE>`
- Publish commit: `<REVIEW_PUBLISH_COMMIT>`

Public PR 可在未认证时通过 REST endpoints 读取 pull、issue comments、reviews、review
comments、files 和 HEAD check-runs。Review body 中的 suppressed comments 也必须逐条 triage。
匿名访问不能回复或 resolve thread；报告限制，不索取凭据，也不使用需要登录的工具做只读 review。

## Local-Only Evidence Inventory

Evidence root: `<EVIDENCE_ROOT>`

| Artifact | Path | Proves | Commit/package identity |
|---|---|---|---|
| RED screenshot/log | `<PATH>` | `<ASSERTION>` | `<IDENTITY>` |
| Focused test report | `<PATH>` | `<ASSERTION>` | `<IDENTITY>` |
| E2E report | `<PATH>` | `<ASSERTION>` | `<IDENTITY>` |
| GREEN screenshots | `<PATH>` | `<ASSERTION>` | `<IDENTITY>` |
| Real integration evidence `[可选]` | `<PATH>` | `<ASSERTION>` | `<IDENTITY>` |
| Fixture/provider/wire log `[可选]` | `<PATH>` | `<ASSERTION>` | `<IDENTITY>` |

- 列出 ignored screenshots、pane captures、fixture logs、test reports、local harness、scripts、
  wire captures 和 provider configurations，并说明每个 artifact 证明哪条 contract。
- 不因文件 ignored 就删除它们；保留用于复现、review follow-up 和后续 framework extraction。
- 若 evidence 不需提交，保留 ignored 状态，并在此记录 path、command、identity、result 和结论。

## Completion Checklist

- [ ] 所有必填 placeholder 已替换；不适用章节已删除。
- [ ] Exact baseline 已 build/deploy，并在预期 behavioral oracle 上 RED。
- [ ] Focused regression 先 RED 后 GREEN。
- [ ] Neighboring tests、full relevant suite、explicit build 和 static analysis 已完成。
- [ ] Publishable 与 dev-only commits 边界清晰。
- [ ] Exact publish HEAD 已 build/deploy，source/deployed hashes 一致。
- [ ] Packaged/deployed E2E 对 exact publish binary GREEN。
- [ ] 真实外部依赖验收已完成，或明确标记 blocked。
- [ ] UI/渲染/交互的 fresh screenshots 已逐图检查并记录 provenance。
- [ ] Review findings 已逐条 triage，accepted fixes 有 RED/GREEN evidence。
- [ ] Evidence inventory 能映射全部 user-visible assertions。
- [ ] Dev 与 publish remote heads 已 push 并确认。

## Optional Follow-Ups

- `<FOLLOW_UP_1>`
- `<FOLLOW_UP_2>`

只记录不属于当前 contract 的后续工作，并为其使用独立 issue、branch 或 PR。