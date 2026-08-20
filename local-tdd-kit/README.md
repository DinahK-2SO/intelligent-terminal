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

## Documents

- `TDD-WORKFLOW.template.md`: issue workflow template and placeholders
- `TOOLS.md`: tools, installation, APIs and input safety
- `BUILD-DEPLOY-E2E.md`: project layers, known failure modes and freshness gates
- `FRAMEWORK-SOURCE.md`: snapshot provenance and update policy
- `examples/Feature.Template.Tests.ps1`: generic Pester starting point

## Artifact Policy

Everything under `local-tdd-kit/artifacts/` is ignored except its `.gitignore`.
Do not commit credentials, prompts, provider configs/homes, wire captures, logs,
screenshots, local paths or account identifiers. Sanitize and deliberately copy only
the small evidence selected for review.