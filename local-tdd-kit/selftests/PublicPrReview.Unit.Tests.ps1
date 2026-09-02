#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    $script:Checker = (Resolve-Path (Join-Path $PSScriptRoot '..\Get-PublicPrReviewSnapshot.ps1')).Path

    function Write-ReviewFixture {
        param(
            [Parameter(Mandatory)][string]$Root,
            [Parameter(Mandatory)][object[]]$Reviews,
            [hashtable]$Comments = @{},
            [object[]]$CheckRuns = @(@{
                name = 'copilot-pull-request-reviewer'
                status = 'completed'
                conclusion = 'success'
                html_url = 'https://example.test/check'
            })
        )

        New-Item -ItemType Directory -Path $Root -Force | Out-Null
        @{
            state = 'open'
            head = @{ sha = 'head-sha' }
        } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $Root 'pr.json') -Encoding utf8
        $Reviews | ConvertTo-Json -Depth 10 -AsArray | Set-Content (Join-Path $Root 'reviews.json') -Encoding utf8
        @{
            total_count = $CheckRuns.Count
            check_runs = $CheckRuns
        } | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $Root 'check-runs.json') -Encoding utf8
        foreach ($entry in $Comments.GetEnumerator()) {
            @($entry.Value) | ConvertTo-Json -Depth 10 -AsArray |
                Set-Content (Join-Path $Root "review-comments-$($entry.Key).json") -Encoding utf8
        }
    }

    function New-CopilotReview {
        param(
            [long]$Id,
            [string]$CommitId,
            [string]$Body
        )

        $submittedAt = [DateTimeOffset]::Parse('2026-09-03T00:00:00Z').AddSeconds($Id)
        [pscustomobject]@{
            id = $Id
            commit_id = $CommitId
            submitted_at = $submittedAt.ToString('o')
            state = 'COMMENTED'
            body = $Body
            html_url = "https://example.test/review/$Id"
            user = @{ login = 'copilot-pull-request-reviewer[bot]' }
        }
    }
}

Describe 'Get-PublicPrReviewSnapshot' -Tag 'Unit' {
    It 'returns only the latest review when no baseline is supplied' {
        $root = Join-Path $TestDrive 'latest'
        Write-ReviewFixture -Root $root -Reviews @(
            (New-CopilotReview 100 'old-sha' '### Suppressed comments (1)\n\n**old.rs:12**\n* Old finding.'),
            (New-CopilotReview 200 'head-sha' 'Copilot reviewed 10 out of 10 changed files and generated no new comments.')
        )

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.LatestCopilotReview.Id | Should -Be 200
        $snapshot.LatestCopilotReview.AtHead | Should -BeTrue
        $snapshot.NewReviewCount | Should -Be 1
        $snapshot.FindingCount | Should -Be 0
        $snapshot.ChecksCompleteAndSuccessful | Should -BeTrue
    }

    It 'returns every Copilot review newer than the supplied baseline' {
        $root = Join-Path $TestDrive 'baseline'
        Write-ReviewFixture -Root $root -Reviews @(
            (New-CopilotReview 100 'old-sha' 'generated no new comments'),
            (New-CopilotReview 200 'middle-sha' 'generated no new comments'),
            (New-CopilotReview 300 'head-sha' 'generated no new comments')
        )

        $snapshot = & $script:Checker -FixtureRoot $root -AfterReviewId 100 | ConvertFrom-Json

        $snapshot.Reviews.Id | Should -Be @(200, 300)
        $snapshot.NewReviewAtHead | Should -BeTrue
    }

    It 'parses suppressed body findings even when generated comments is zero' {
        $root = Join-Path $TestDrive 'suppressed'
        $body = @'
### Suppressed comments (1)

**tools/wta/src/protocol/acp/client.rs:4875**
* A policy change can silently discard the first prompt.

- **Files reviewed:** 179/181 changed files
- **Comments generated:** 0 new
'@
        Write-ReviewFixture -Root $root -Reviews @((New-CopilotReview 400 'head-sha' $body))

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.LatestCopilotReview.GeneratedCommentCount | Should -Be 0
        $snapshot.FindingCount | Should -Be 1
        $snapshot.Findings[0].Kind | Should -Be 'SuppressedReviewBody'
        $snapshot.Findings[0].Path | Should -Be 'tools/wta/src/protocol/acp/client.rs'
        $snapshot.Findings[0].Line | Should -Be 4875
    }

    It 'includes visible inline comments for each newly selected review' {
        $root = Join-Path $TestDrive 'inline'
        $review = New-CopilotReview 500 'head-sha' 'generated 1 comment'
        $comment = @{
            commit_id = 'head-sha'
            path = 'tools/wta/src/app.rs'
            line = 42
            original_line = 40
            body = 'Visible finding.'
            html_url = 'https://example.test/comment/1'
            user = @{ login = 'Copilot' }
        }
        Write-ReviewFixture -Root $root -Reviews @($review) -Comments @{ 500 = @($comment) }

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.FindingCount | Should -Be 1
        $snapshot.Findings[0].Kind | Should -Be 'InlineReviewComment'
        $snapshot.Findings[0].Line | Should -Be 42
    }

    It 'fails closed when declared visible comments are not published' {
        $root = Join-Path $TestDrive 'inline-mismatch'
        Write-ReviewFixture -Root $root -Reviews @(
            (New-CopilotReview 550 'head-sha' 'generated 1 comment')
        )

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.FindingCount | Should -Be 1
        $snapshot.Findings[0].Kind | Should -Be 'ReviewCommentCountMismatch'
    }

    It 'fails closed when a suppressed count cannot be parsed into locations' {
        $root = Join-Path $TestDrive 'unparsed'
        Write-ReviewFixture -Root $root -Reviews @(
            (New-CopilotReview 600 'head-sha' '### Suppressed comments (1)\n\nNo location block was returned.')
        )

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.FindingCount | Should -Be 2
        $snapshot.Findings.Kind | Should -Contain 'UnparsedSuppressedReviewBody'
        $snapshot.Findings.Kind | Should -Contain 'UnparsedGeneratedCommentCount'
        { & $script:Checker -FixtureRoot $root -FailOnFindings | Out-Null } |
            Should -Throw '*require triage*'
    }

    It 'reports an incomplete or failed check from a multi-item response' {
        $root = Join-Path $TestDrive 'checks'
        $checks = @(
            @{ name = 'reviewer'; status = 'completed'; conclusion = 'success'; html_url = 'https://example.test/reviewer' },
            @{ name = 'build'; status = 'in_progress'; conclusion = $null; html_url = 'https://example.test/build' }
        )
        Write-ReviewFixture -Root $root -Reviews @(
            (New-CopilotReview 700 'head-sha' 'generated no new comments')
        ) -CheckRuns $checks

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.CheckCount | Should -Be 2
        $snapshot.ChecksCompleteAndSuccessful | Should -BeFalse
    }

    It 'fails the check gate when no exact-head checks are visible' {
        $root = Join-Path $TestDrive 'no-checks'
        Write-ReviewFixture -Root $root -Reviews @(
            (New-CopilotReview 650 'head-sha' 'generated no new comments')
        ) -CheckRuns @()

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.CheckCount | Should -Be 0
        $snapshot.ChecksCompleteAndSuccessful | Should -BeFalse
        { & $script:Checker -FixtureRoot $root -RequireSuccessfulChecks | Out-Null } |
            Should -Throw '*checks are absent, incomplete, or unsuccessful*'
    }

    It 'paginates reviews and check runs through the fixture transport' {
        $root = Join-Path $TestDrive 'pagination'
        $reviews = @(1..100 | ForEach-Object {
            New-CopilotReview $_ 'old-sha' 'generated no new comments'
        })
        $checks = @(1..100 | ForEach-Object {
            @{ name = "check-$_"; status = 'completed'; conclusion = 'success'; html_url = "https://example.test/check/$_" }
        })
        Write-ReviewFixture -Root $root -Reviews $reviews -CheckRuns $checks
        $reviews | ConvertTo-Json -Depth 10 -AsArray |
            Set-Content (Join-Path $root 'reviews-page-1.json') -Encoding utf8
        @((New-CopilotReview 101 'head-sha' 'generated no new comments')) |
            ConvertTo-Json -Depth 10 -AsArray |
            Set-Content (Join-Path $root 'reviews-page-2.json') -Encoding utf8
        @{ total_count = 100; check_runs = $checks } | ConvertTo-Json -Depth 10 |
            Set-Content (Join-Path $root 'check-runs-page-1.json') -Encoding utf8
        @{ total_count = 101; check_runs = @(@{
            name = 'late-check'; status = 'in_progress'; conclusion = $null; html_url = 'https://example.test/late-check'
        }) } | ConvertTo-Json -Depth 10 |
            Set-Content (Join-Path $root 'check-runs-page-2.json') -Encoding utf8

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.LatestCopilotReview.Id | Should -Be 101
        $snapshot.CheckCount | Should -Be 101
        $snapshot.ChecksCompleteAndSuccessful | Should -BeFalse
        { & $script:Checker -FixtureRoot $root -RequireSuccessfulChecks | Out-Null } |
            Should -Throw '*checks are absent, incomplete, or unsuccessful*'
    }

    It 'fails closed if the PR head changes during collection' {
        $root = Join-Path $TestDrive 'head-drift'
        Write-ReviewFixture -Root $root -Reviews @(
            (New-CopilotReview 800 'head-sha' 'generated no new comments')
        )
        @{
            state = 'open'
            head = @{ sha = 'new-head-sha' }
        } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $root 'pr-final.json') -Encoding utf8

        { & $script:Checker -FixtureRoot $root | Out-Null } |
            Should -Throw '*PR head changed*'
    }

    It 'fails closed on unknown generated-comment formats and count mismatches' {
        $root = Join-Path $TestDrive 'body-integrity'
        $body = @'
### Suppressed comments (1)

**one.rs:1**
* First finding.
**two.rs:2**
* Second finding.
'@
        Write-ReviewFixture -Root $root -Reviews @((New-CopilotReview 900 'head-sha' $body))

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.Findings.Kind | Should -Contain 'UnparsedSuppressedReviewBody'
        $snapshot.Findings.Kind | Should -Contain 'UnparsedGeneratedCommentCount'
    }

    It 'fails closed when a suppressed section omits its count' {
        $root = Join-Path $TestDrive 'missing-suppressed-count'
        Write-ReviewFixture -Root $root -Reviews @(
            (New-CopilotReview 950 'head-sha' '### Suppressed comments\n\nNo count was rendered.\n\nComments generated:** 0')
        )

        $snapshot = & $script:Checker -FixtureRoot $root | ConvertFrom-Json

        $snapshot.Findings.Kind | Should -Contain 'UnparsedSuppressedReviewBody'
    }

    It 'fails immediately on malformed review and check payloads' {
        $reviewRoot = Join-Path $TestDrive 'malformed-review'
        Write-ReviewFixture -Root $reviewRoot -Reviews @(
            (New-CopilotReview 1000 'head-sha' 'generated no new comments')
        )
        @(@{ unexpected = 'shape' }) | ConvertTo-Json -AsArray |
            Set-Content (Join-Path $reviewRoot 'reviews-page-1.json') -Encoding utf8

        { & $script:Checker -FixtureRoot $reviewRoot | Out-Null } |
            Should -Throw '*Reviews page 1 payload is missing required properties*'

        $checkRoot = Join-Path $TestDrive 'malformed-checks'
        Write-ReviewFixture -Root $checkRoot -Reviews @(
            (New-CopilotReview 1001 'head-sha' 'generated no new comments')
        )
        @{ unexpected = 'shape' } | ConvertTo-Json |
            Set-Content (Join-Path $checkRoot 'check-runs-page-1.json') -Encoding utf8

        { & $script:Checker -FixtureRoot $checkRoot | Out-Null } |
            Should -Throw '*missing the check_runs property*'
    }

    It 'enforces the baseline exact-head review gate' {
        $root = Join-Path $TestDrive 'review-gate'
        Write-ReviewFixture -Root $root -Reviews @(
            (New-CopilotReview 1100 'head-sha' 'generated no new comments')
        )

        { & $script:Checker -FixtureRoot $root -AfterReviewId 1000 -RequireNewReviewAtHead | Out-Null } |
            Should -Not -Throw
        { & $script:Checker -FixtureRoot $root -AfterReviewId 1100 -RequireNewReviewAtHead | Out-Null } |
            Should -Throw '*No Copilot review newer than 1100*'
    }
}