# Portable Local TDD Kit

A self-contained, local-only test-driven-development kit for Intelligent Terminal.
It is designed to be cherry-picked as one commit onto an issue branch. It does not
register online automation and is not intended to merge into `main` unchanged.

## Fresh Machine

```powershell
# After cherry-picking the kit commit:
local-tdd-kit\install-tools.cmd
pwsh -File local-tdd-kit/bootstrap.ps1 -Check

Invoke-Pester local-tdd-kit/selftests/ItE2E.Unit.Tests.ps1 -Tag Unit
Invoke-Pester local-tdd-kit/selftests/ItE2E.Input.Tests.ps1 -Tag Input
```

Copy `TDD-WORKFLOW.template.md` into the issue's dev-only tracking location and
replace every placeholder before changing product code.

For a local-only investigation that must not add the kit to the feature diff,
copy the kit contents to an ignored `.local-tdd-kit-run\kit` directory instead.
Add `.local-tdd-kit-run/` to the repository's local Git exclude, record the
source kit commit in the task handoff, and run the copied selftests before use.
The selftests are location-independent; reports and provider evidence remain
under the ignored `.local-tdd-kit-run\artifacts` tree.

## Live Validation

An installed Intelligent Terminal package and an unlocked interactive desktop are
required. Pin the package under test:

```powershell
$env:ITE2E_PACKAGE = 'Dev'
Invoke-Pester local-tdd-kit/selftests/ItE2E.Live.Tests.ps1 -Tag Live
Invoke-Pester local-tdd-kit/selftests/ItE2E.AgentInput.Tests.ps1 -Tag AgentInput
```

`AgentInput` uses a local deterministic ACP fixture. It requires no provider login,
credential or network model response.

## Build and Deploy

```powershell
pwsh -File local-tdd-kit/Invoke-BuildDeploy.ps1
pwsh -File local-tdd-kit/Verify-DeploymentFreshness.ps1
```

Read `BUILD-DEPLOY-E2E.md` before trusting a packaged E2E result. A green build alone
does not prove that the installed package or live processes contain that build.

Agent-driven runs must remain continuous across non-conflicting questions and status requests.
Keep an active-task ledger, answer the interruption briefly, then execute the next incomplete
action in the same response. Missing or truncated helper output is `unknown`: recover from the
owned terminal or durable pipeline journal first, and rerun only cheap idempotent checks.

For an uninterrupted bounded build/deploy/freshness/E2E cycle, use the durable runner:

```powershell
pwsh -File local-tdd-kit/Invoke-LocalTddPipeline.ps1 `
	-E2EPath test/e2e/tests/<Feature>.Tests.ps1

pwsh -File local-tdd-kit/Get-LocalTddPipelineStatus.ps1 `
	-JournalPath local-tdd-kit/artifacts/pipeline-<HEAD>-<UTC>/pipeline-state.json
```

The runner replaces its phase journal atomically so readers never observe partial JSON. It records
preflight, build/deploy/freshness, optional packaged E2E, and final source-fingerprint verification.
It deliberately does not pass `-Launch` to the build script; E2E
owns the exact window launch. An AI coding agent must still invoke the runner with synchronous
terminal execution and no tool timeout. The journal lets a later turn distinguish `passed`,
`failed`, live `running`, abandoned `interrupted`, and semantically corrupt `invalid` state, but
it cannot wake an agent turn that was already ended. If VS Code or the execution
host terminates the runner process, machine-side continuation also stops and status becomes
`interrupted`.

## Documents

- `TDD-WORKFLOW.template.md`: issue workflow template and placeholders
- `TOOLS.md`: tools, installation, APIs and input safety
- `BUILD-DEPLOY-E2E.md`: project layers, known failure modes and freshness gates
- `Invoke-LocalTddPipeline.ps1`: durable bounded workflow and atomic phase journal
- `Get-LocalTddPipelineStatus.ps1`: passed/failed/running/interrupted/invalid classification
- `FRAMEWORK-SOURCE.md`: snapshot provenance and update policy
- `examples/Feature.Template.Tests.ps1`: generic Pester starting point

## Artifact Policy

Everything under `local-tdd-kit/artifacts/` is ignored except its `.gitignore`.
Do not commit credentials, prompts, provider configs/homes, wire captures, logs,
screenshots, local paths or account identifiers. Sanitize and deliberately copy only
the small evidence selected for review.