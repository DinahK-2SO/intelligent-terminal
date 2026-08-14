# Feature/Fix Handoff Template

> TEMPLATE: When instantiating this handoff, replace each `<PLACEHOLDER>` as
> its evidence becomes available. Delete optional sections that do not apply.
> Do not carry details from a previous work item into a new branch. Keep the
> repository reference below the `---` divider unchanged unless its long-lived
> architecture changes.

## Placeholder Checklist

Fill these before implementation begins:

- Identity: `<WORK_ITEM_TITLE>`, `<LAST_SYNCHRONIZED_YYYY-MM-DD>`, `<BASE_SHA>`,
  branch/remote names, and `<ISSUE_OR_PR>`.
- Scope: `<CURRENT_STAGE>`, `<USER_VISIBLE_CONTRACT>`, non-goals, guardrails,
  `<OPEN_FOLLOW_UPS>`, `<REVIEW_EVIDENCE_DIR>`, and any
  `<PUBLISH_SCOPE_EXCEPTION>`.
- Discovery: ownership path, falsifiable hypothesis, discriminating check,
  deterministic reproduction, setup preconditions, RED oracle, and the nearest
  existing test/framework that can be reused.

Fill these as implementation evidence becomes available:

- RED/GREEN results, owning abstraction, state/API changes, invariants,
  performance notes, rejected alternatives, and artifact paths.
- Review decisions with rationale, resolution, and focused validation.

Fill these before publishing or handoff completion:

- Full-suite/build/deployment/E2E results, visual evidence, remaining gaps,
  source/deployed hashes, `<PUBLISHABLE_COMMIT>`, and `<PUBLISH_HEAD>`.
- Replace any remaining inline `<PLACEHOLDER>` or explicitly mark it `N/A`.

> Last synchronized: `<LAST_SYNCHRONIZED_YYYY-MM-DD>`
>
> This dev-only section tracks `<WORK_ITEM_TITLE>`. Product behavior and
> committed tests remain the source of truth.

Branches created from `origin/main@<BASE_SHA>`:

- dev: `<DEV_BRANCH>` -> `<DEV_REMOTE>`
- publish: `<PUBLISH_BRANCH>` -> `<PUBLISH_REMOTE>`
- issue / pull request: `<ISSUE_OR_PR>`

Publish scope excludes this handoff and local-only screenshots, reports, logs,
and experiments unless `<PUBLISH_SCOPE_EXCEPTION>` explicitly says otherwise.

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
- Current publishable commit: `<PUBLISHABLE_COMMIT>`.
- Current publish head: `<PUBLISH_HEAD>`.
- Excluded work: `<OPEN_FOLLOW_UPS>`.

### E2E Reuse and Test-Framework Modularization

- Reuse or extend existing tests, fixtures, helpers, and E2E frameworks first.
  Record the nearest reusable coverage at `<EXISTING_TEST_SURFACE>` and explain
  why it is sufficient or insufficient for the real user workflow.
- When the existing framework cannot exercise the real user operation, a local
  E2E framework or orchestration layer may be developed to establish RED/GREEN
  evidence. Keep it under `<LOCAL_E2E_FRAMEWORK_PATH>` and design clear module
  boundaries, inputs, outputs, and cleanup so it can become an independent PR.
- Do not include a large new test framework, general-purpose harness rewrite,
  or unrelated infrastructure in the feature/fix publishable commit. Commit
  only tests that fit naturally in an existing framework; track the modular
  framework extraction under `<OPEN_FOLLOW_UPS>` for a separate branch/PR.
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

`<LAST_SYNCHRONIZED_YYYY-MM-DD>`: `<CURRENT_STAGE>`

### User-Visible Contract

`<USER_VISIBLE_CONTRACT>`

List concrete behavior, preserved workflows, edge cases, and explicit
non-goals. Prefer observable outcomes over implementation details.

### Current Ownership Hypothesis

```text
<ENTRY_POINT>
  -> <ROUTING_LAYER>
  -> <OWNING_ABSTRACTION>
  -> <STATE_OR_OUTPUT>
```

- Owning code path: `<OWNERSHIP_PATH>`
- Falsifiable hypothesis: `<CURRENT_HYPOTHESIS>`
- Cheapest discriminating check: `<DISCRIMINATING_CHECK>`

### Reproduction and RED Oracle

Framework / fixture: `<TEST_FRAMEWORK_AND_FIXTURE>`

1. `<REPRO_STEP_1>`
2. `<REPRO_STEP_2>`
3. `<REPRO_STEP_3>`
4. Prove setup preconditions: `<SETUP_PRECONDITIONS>`.
5. Capture ignored evidence at `<ARTIFACT_PATHS>`.

- RED oracle: `<RED_ORACLE>`
- Expected failure location/message: `<EXPECTED_FAILURE>`
- Evidence that setup itself succeeded: `<VALID_SETUP_EVIDENCE>`

### Implementation

`<IMPLEMENTATION_SUMMARY>`

- Owning abstraction: `<OWNING_ABSTRACTION>`
- State or API changes: `<STATE_OR_API_CHANGES>`
- Preserved invariants: `<PRESERVED_INVARIANTS>`
- Performance implications: `<PERFORMANCE_NOTES>`
- Rejected alternatives and rationale: `<REJECTED_ALTERNATIVES>`

### TDD and Validation Evidence

- Focused RED: `<FOCUSED_RED_EVIDENCE>`
- Live / E2E RED: `<LIVE_RED_EVIDENCE>`
- Focused GREEN: `<FOCUSED_GREEN_EVIDENCE>`
- Neighboring tests: `<NEIGHBORING_TEST_RESULTS>`
- Full suite: `<FULL_SUITE_RESULTS>`
- Explicit-target build: `<BUILD_RESULTS>`
- Exact deployed package: `<PACKAGE_SELECTOR_AND_IDENTITY>`
- Source/deployed SHA-256: `<SOURCE_HASH>` / `<DEPLOYED_HASH>`
- Packaged E2E: `<PACKAGED_E2E_RESULTS>`
- Screenshot paths: `<RED_SCREENSHOTS>` / `<GREEN_SCREENSHOTS>`
- Visual inspection: `<VISUAL_EVIDENCE>`
- Remaining test gaps: `<REMAINING_TEST_GAPS>`

For UI or terminal-rendering changes, screenshots are required evidence, not
optional decoration. Capture the failing state and the fixed state from the
real user workflow. Inspect and record that the target state is visible, output
is nonblank, layout is stable, and controls/text do not overlap or clip. Cover
all relevant pane positions, window sizes, themes, or interaction modes named
by `<USER_VISIBLE_CONTRACT>`.

### Review Triage

For every review round, append a short entry using this format:

```text
<REVIEW_DATE> <REVIEW_ID_OR_HEAD_SHA>
- Finding: <PATH_AND_SUMMARY>
- Decision: accept | decline | escalate
- Rationale: <TECHNICAL_REASONING>
- RED: <FAILURE_EVIDENCE_OR_N/A>
- Resolution: <CHANGE_OR_EXPLICIT_DECLINE>
- GREEN: <VALIDATION_EVIDENCE>
- Publish commit: <SHA_OR_N/A>
```

Current review status: `<REVIEW_STATUS>`
Open review items: `<OPEN_REVIEW_ITEMS_OR_NONE>`

### Local-Only Evidence

`<ARTIFACT_PATHS>`

List ignored screenshots, pane captures, fixture logs, test reports, local E2E
frameworks, scripts, wire captures, and provider configurations. State which
artifact proves each user-visible assertion.

- Do not delete local E2E frameworks, scripts, wire captures, provider configs,
  screenshots, reports, or logs merely because they are ignored. Preserve them
  for reproduction, review follow-up, and extraction into a separate PR.
- If a screenshot or other evidence must be committed for review, copy the
  final selected artifact into the designated non-ignored
  `<REVIEW_EVIDENCE_DIR>`. Do not force-add the ignored working artifact.
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

- `<WORK_ITEM_GUARDRAIL_1>`
- `<WORK_ITEM_GUARDRAIL_2>`
- `<WORK_ITEM_GUARDRAIL_3>`
- Do not infer user-visible behavior only from internal state; validate the
  actual output or workflow.
- Do not include unrelated fixes discovered during investigation. Record them
  under follow-ups and use a separate branch/PR.
- Do not delete ignored local E2E frameworks, scripts, wire/provider configs,
  screenshots, or logs. Preserve them and record their paths.
- Do not force-add ignored screenshots. Copy review-selected evidence into
  `<REVIEW_EVIDENCE_DIR>` when it must be committed.
- Format only touched files; avoid repository-wide mechanical churn.

### Optional Follow-Ups

- `<FOLLOW_UP_TITLE>`: `<WHY_EXCLUDED>`, `<EVIDENCE>`, `<PROPOSED_NEXT_STEP>`.
- If none: `None`.

---
