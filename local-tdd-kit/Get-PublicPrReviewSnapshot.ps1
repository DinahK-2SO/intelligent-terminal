[CmdletBinding()]
param(
    [string]$Owner = 'microsoft',
    [string]$Repo = 'intelligent-terminal',
    [int]$PrNumber = 505,
    [long]$AfterReviewId = 0,
    [switch]$AllReviews,
    [switch]$RequireNewReviewAtHead,
    [switch]$RequireSuccessfulChecks,
    [switch]$FailOnFindings,
    [string]$OutputPath,
    [string]$FixtureRoot
)

$ErrorActionPreference = 'Stop'
$headers = @{
    Accept = 'application/vnd.github+json'
    'User-Agent' = 'intelligent-terminal-public-review-check'
    'Cache-Control' = 'no-cache'
}
$apiRoot = "https://api.github.com/repos/$Owner/$Repo"
$nonce = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

function Get-FixtureJson {
    param([Parameter(Mandatory)][string]$Name)

    $path = Join-Path $FixtureRoot $Name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return @()
    }
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

function Invoke-PublicGitHubGet {
    param([Parameter(Mandatory)][string]$Uri)

    if ($FixtureRoot) {
        $page = if ($Uri -match '[?&]page=(\d+)') { [int]$Matches[1] } else { 1 }
        if ($Uri -match '/reviews/(?<reviewId>\d+)/comments') {
            $paged = "review-comments-$($Matches['reviewId'])-page-$page.json"
            $fallback = "review-comments-$($Matches['reviewId']).json"
        }
        elseif ($Uri -match '/pulls/\d+/reviews') {
            $paged = "reviews-page-$page.json"
            $fallback = 'reviews.json'
        }
        elseif ($Uri -match '/check-runs') {
            $paged = "check-runs-page-$page.json"
            $fallback = 'check-runs.json'
        }
        else {
            $script:PrFixtureReads = $script:PrFixtureReads + 1
            $paged = if ($script:PrFixtureReads -gt 1 -and (Test-Path (Join-Path $FixtureRoot 'pr-final.json'))) {
                'pr-final.json'
            }
            else {
                'pr.json'
            }
            $fallback = $paged
        }

        if (Test-Path -LiteralPath (Join-Path $FixtureRoot $paged)) {
            return Get-FixtureJson $paged
        }
        if ($page -eq 1) {
            return Get-FixtureJson $fallback
        }
        return @()
    }
    Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers
}

function ConvertTo-ItemArray {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }
    if ($Value -is [array]) {
        return @($Value.GetEnumerator())
    }
    return @($Value)
}

function Assert-ItemProperties {
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][string[]]$RequiredProperties,
        [Parameter(Mandatory)][string]$Context
    )

    $names = @($Item.PSObject.Properties.Name)
    $missing = @($RequiredProperties | Where-Object { $names -notcontains $_ })
    if ($missing.Count -gt 0) {
        throw "$Context payload is missing required properties: $($missing -join ', ')."
    }
}

function Get-PagedPublicGitHubItems {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string[]]$RequiredProperties,
        [Parameter(Mandatory)][string]$Context
    )

    $items = @()
    for ($page = 1; ; $page++) {
        $separator = if ($Uri.Contains('?')) { '&' } else { '?' }
        $response = Invoke-PublicGitHubGet "$Uri${separator}per_page=100&page=$page&nonce=$nonce"
        $batch = @(ConvertTo-ItemArray $response)
        foreach ($item in $batch) {
            Assert-ItemProperties $item $RequiredProperties "$Context page $page"
        }
        $items += $batch
        if ($batch.Count -lt 100) {
            break
        }
    }
    return $items
}

function Get-PagedPublicCheckRuns {
    param([Parameter(Mandatory)][string]$Uri)

    $items = @()
    for ($page = 1; ; $page++) {
        $separator = if ($Uri.Contains('?')) { '&' } else { '?' }
        $response = Invoke-PublicGitHubGet "$Uri${separator}per_page=100&page=$page&nonce=$nonce"
        if ($null -eq $response -or $response.PSObject.Properties.Name -notcontains 'check_runs') {
            throw "Check-runs page $page payload is missing the check_runs property."
        }
        $batch = @(ConvertTo-ItemArray $response.check_runs)
        foreach ($item in $batch) {
            Assert-ItemProperties $item @('name', 'status', 'conclusion', 'html_url') "Check-runs page $page"
        }
        $items += $batch
        if ($batch.Count -lt 100) {
            break
        }
    }
    return $items
}

function Get-ReviewBodyFinding {
    param([Parameter(Mandatory)]$Review)

    $body = [string]$Review.body
    $matches = [regex]::Matches(
        $body,
        '(?ms)^\*\*(?<location>[^*\r\n]+:\d+)\*\*\r?\n\*\s+(?<message>.*?)(?=^\*\*[^*\r\n]+:\d+\*\*|^-\s+\*\*Files reviewed|^</details>|\z)'
    )
    $findings = @($matches | ForEach-Object {
        $location = $_.Groups['location'].Value
        $separator = $location.LastIndexOf(':')
        [pscustomobject][ordered]@{
            Kind = 'SuppressedReviewBody'
            ReviewId = [long]$Review.id
            CommitId = [string]$Review.commit_id
            Path = $location.Substring(0, $separator)
            Line = [int]$location.Substring($separator + 1)
            Message = ($_.Groups['message'].Value -replace '\s+', ' ').Trim()
            Url = [string]$Review.html_url
        }
    })

    $hasSuppressedSection = $body -match '(?i)(?:Suppressed comments?|Comments suppressed due to low confidence)'
    $suppressedCount = $null
    if ($body -match '(?i)(?:Suppressed comments?|Comments suppressed due to low confidence)\s*\((\d+)\)') {
        $suppressedCount = [int]$Matches[1]
    }
    $parsedCount = $findings.Count
    if ($null -eq $suppressedCount -and ($hasSuppressedSection -or $parsedCount -gt 0)) {
        $findings += [pscustomobject][ordered]@{
            Kind = 'UnparsedSuppressedReviewBody'
            ReviewId = [long]$Review.id
            CommitId = [string]$Review.commit_id
            Path = $null
            Line = $null
            Message = "Review contains a suppressed-comment section or location block without a recognized suppressed count. Parsed $parsedCount location block(s). Inspect the review body."
            Url = [string]$Review.html_url
        }
    }
    elseif ($null -ne $suppressedCount -and $suppressedCount -ne $parsedCount) {
        $findings += [pscustomobject][ordered]@{
            Kind = 'UnparsedSuppressedReviewBody'
            ReviewId = [long]$Review.id
            CommitId = [string]$Review.commit_id
            Path = $null
            Line = $null
            Message = "Review declares $suppressedCount suppressed comment(s), but $parsedCount location block(s) were parsed. Inspect the review body."
            Url = [string]$Review.html_url
        }
    }
    return $findings
}

function Get-GeneratedCommentCount {
    param([string]$Body)

    if ($Body -match '(?i)Comments generated:\*\*\s*(\d+)') {
        return [int]$Matches[1]
    }
    if ($Body -match '(?i)generated\s+(\d+)\s+(?:new\s+)?comments?') {
        return [int]$Matches[1]
    }
    if ($Body -match '(?i)generated no new comments') {
        return 0
    }
    return $null
}

$script:PrFixtureReads = 0
$pr = Invoke-PublicGitHubGet "$apiRoot/pulls/$PrNumber`?nonce=$nonce"
if ($null -eq $pr -or $pr.PSObject.Properties.Name -notcontains 'head' -or -not $pr.head -or -not $pr.head.sha) {
    throw "PR #$PrNumber was not found or did not include a head SHA."
}
$reviews = @(Get-PagedPublicGitHubItems `
    "$apiRoot/pulls/$PrNumber/reviews" `
    @('id', 'commit_id', 'submitted_at', 'body', 'html_url', 'user') `
    'Reviews')
$checks = @(Get-PagedPublicCheckRuns "$apiRoot/commits/$($pr.head.sha)/check-runs")
$finalPr = Invoke-PublicGitHubGet "$apiRoot/pulls/$PrNumber`?nonce=$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"
if ($null -eq $finalPr -or $finalPr.PSObject.Properties.Name -notcontains 'head' -or -not $finalPr.head -or -not $finalPr.head.sha) {
    throw "The final PR snapshot did not include a head SHA."
}
if ([string]$finalPr.head.sha -ne [string]$pr.head.sha) {
    throw "PR head changed from $($pr.head.sha) to $($finalPr.head.sha) while collecting the review snapshot. Retry the snapshot."
}

$copilotReviews = @($reviews | Where-Object {
    $_.user.login -match '(?i)^copilot-pull-request-reviewer(\[bot\])?$'
} | Sort-Object submitted_at, id)
$latest = @($copilotReviews | Select-Object -Last 1)
if ($AllReviews) {
    $selectedReviews = $copilotReviews
}
elseif ($AfterReviewId -gt 0) {
    $selectedReviews = @($copilotReviews | Where-Object { [long]$_.id -gt $AfterReviewId })
}
else {
    $selectedReviews = $latest
}

$findings = @()
$reviewSummaries = @()
foreach ($review in $selectedReviews) {
    $bodyFindings = @(Get-ReviewBodyFinding $review)
    $generatedCommentCount = Get-GeneratedCommentCount ([string]$review.body)
    if ($null -eq $generatedCommentCount) {
        $bodyFindings += [pscustomobject][ordered]@{
            Kind = 'UnparsedGeneratedCommentCount'
            ReviewId = [long]$review.id
            CommitId = [string]$review.commit_id
            Path = $null
            Line = $null
            Message = 'The Copilot review body did not contain a recognized generated-comment count. Inspect the review body.'
            Url = [string]$review.html_url
        }
    }
    $inlineComments = @(Get-PagedPublicGitHubItems `
        "$apiRoot/pulls/$PrNumber/reviews/$($review.id)/comments" `
        @('commit_id', 'path', 'body', 'html_url', 'user') `
        "Review $($review.id) comments")
    $inlineFindings = @($inlineComments | Where-Object {
        $_.user.login -match '(?i)^(?:copilot|copilot-pull-request-reviewer)(?:\[bot\])?$'
    } | ForEach-Object {
        [pscustomobject][ordered]@{
            Kind = 'InlineReviewComment'
            ReviewId = [long]$review.id
            CommitId = [string]$_.commit_id
            Path = [string]$_.path
            Line = if ($_.PSObject.Properties.Name -contains 'line' -and $_.line) {
                [int]$_.line
            }
            elseif ($_.PSObject.Properties.Name -contains 'original_line' -and $_.original_line) {
                [int]$_.original_line
            }
            else {
                $null
            }
            Message = (([string]$_.body) -replace '\s+', ' ').Trim()
            Url = [string]$_.html_url
        }
    })
    if ($null -ne $generatedCommentCount -and $generatedCommentCount -ne $inlineFindings.Count) {
        $bodyFindings += [pscustomobject][ordered]@{
            Kind = 'ReviewCommentCountMismatch'
            ReviewId = [long]$review.id
            CommitId = [string]$review.commit_id
            Path = $null
            Line = $null
            Message = "Review declares $generatedCommentCount generated comment(s), but the review-comments endpoint returned $($inlineFindings.Count). Retry or inspect the review."
            Url = [string]$review.html_url
        }
    }
    $findings += $bodyFindings
    $findings += $inlineFindings
    $reviewSummaries += [pscustomobject][ordered]@{
        Id = [long]$review.id
        CommitId = [string]$review.commit_id
        SubmittedAt = [string]$review.submitted_at
        State = [string]$review.state
        AtHead = ([string]$review.commit_id -eq [string]$pr.head.sha)
        GeneratedCommentCount = $generatedCommentCount
        BodyFindingCount = $bodyFindings.Count
        InlineCommentCount = $inlineFindings.Count
        Url = [string]$review.html_url
    }
}

$latestSummary = if ($latest.Count -eq 1) {
    $latestReview = $latest[0]
    [pscustomobject][ordered]@{
        Id = [long]$latestReview.id
        CommitId = [string]$latestReview.commit_id
        SubmittedAt = [string]$latestReview.submitted_at
        State = [string]$latestReview.state
        AtHead = ([string]$latestReview.commit_id -eq [string]$pr.head.sha)
        GeneratedCommentCount = Get-GeneratedCommentCount ([string]$latestReview.body)
        Url = [string]$latestReview.html_url
    }
}
else {
    $null
}

$badChecks = @($checks | Where-Object {
    $_.status -ne 'completed' -or $_.conclusion -notin @('success', 'skipped', 'neutral')
})
$newReviewAtHead = $reviewSummaries.Count -gt 0 -and $reviewSummaries[-1].AtHead
$snapshot = [pscustomobject][ordered]@{
    SchemaVersion = 1
    CapturedAt = [DateTimeOffset]::UtcNow.ToString('o')
    Owner = $Owner
    Repo = $Repo
    PrNumber = $PrNumber
    HeadOid = [string]$pr.head.sha
    PrState = [string]$pr.state
    BaselineReviewId = $AfterReviewId
    LatestCopilotReview = $latestSummary
    NewReviewCount = $reviewSummaries.Count
    NewReviewAtHead = $newReviewAtHead
    Reviews = $reviewSummaries
    FindingCount = $findings.Count
    Findings = $findings
    CheckCount = $checks.Count
    ChecksCompleteAndSuccessful = ($checks.Count -gt 0 -and $badChecks.Count -eq 0)
    Checks = @($checks | ForEach-Object {
        [pscustomobject][ordered]@{
            Name = [string]$_.name
            Status = [string]$_.status
            Conclusion = [string]$_.conclusion
            Url = [string]$_.html_url
        }
    })
    Limitations = @(
        'Public REST does not expose authoritative review-thread resolution state.',
        'Pass the prior LatestCopilotReview.Id as -AfterReviewId to inspect every newly published review without re-reporting older findings.'
    )
}

$json = $snapshot | ConvertTo-Json -Depth 10
if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath), $json, [Text.UTF8Encoding]::new($false))
}
$json

if ($RequireNewReviewAtHead -and -not $newReviewAtHead) {
    throw "No Copilot review newer than $AfterReviewId was published at PR head $($pr.head.sha)."
}
if ($RequireSuccessfulChecks -and ($checks.Count -eq 0 -or $badChecks.Count -gt 0)) {
    throw "Exact-head checks are absent, incomplete, or unsuccessful for $($pr.head.sha)."
}
if ($FailOnFindings -and $findings.Count -gt 0) {
    throw "$($findings.Count) new Copilot review finding(s) require triage."
}