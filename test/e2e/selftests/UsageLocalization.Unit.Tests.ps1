#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $appRoot = Join-Path $repoRoot 'src\cascadia\TerminalApp\Resources'
    $settingsRoot = Join-Path $repoRoot 'src\cascadia\TerminalSettingsEditor\Resources'
    $pseudoLocales = @('qps-ploc', 'qps-ploca', 'qps-plocm')
    $appKeys = @(
        'FreOverlay_ShowTokenUsageAndCostLabel.Text',
        'FreOverlay_ShowTokenUsageAndCostDescription.Text',
        'UsageGroup/[using:Windows.UI.Xaml.Automation]AutomationProperties/Name',
        'Usage_TokensUnit',
        'Usage_ContextWindowLabel'
    )

    function Read-ResourceXml([string]$Path) {
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load($Path)
        $xml
    }

    function Get-ResourceValue($Xml, [string]$Key) {
        $Xml.SelectSingleNode("/root/data[@name='$Key']/value").InnerText
    }
}

Describe 'Usage localization resources' -Tag 'Unit' {
    It 'uses the final source-neutral and availability-conditional English copy' {
        $english = Read-ResourceXml (Join-Path $appRoot 'en-US\Resources.resw')
        $title = Get-ResourceValue $english 'FreOverlay_ShowTokenUsageAndCostLabel.Text'
        $description = Get-ResourceValue $english 'FreOverlay_ShowTokenUsageAndCostDescription.Text'

        $title | Should -Be 'Show context usage and billing'
        $description | Should -Be 'When available, show context-window usage and reported cost or credits in the terminal bottom bar.'
        "$title $description" | Should -Not -Match '(?i)provider|monetary|token usage'
    }

    It 'defines every usage key exactly once in every TerminalApp locale with a UTF-8 BOM' {
        $files = @(Get-ChildItem $appRoot -Directory | ForEach-Object { Join-Path $_.FullName 'Resources.resw' })
        $files.Count | Should -BeGreaterThan 0

        foreach ($file in $files) {
            $bytes = [System.IO.File]::ReadAllBytes($file)
            ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) |
                Should -BeTrue -Because "$file must retain its UTF-8 BOM"
            ($bytes[3] -eq 0xEF -and $bytes[4] -eq 0xBB -and $bytes[5] -eq 0xBF) |
                Should -BeFalse -Because "$file must contain exactly one UTF-8 BOM"

            $xml = Read-ResourceXml $file
            foreach ($key in $appKeys) {
                $nodes = @($xml.SelectNodes("/root/data[@name='$key']"))
                $nodes.Count | Should -Be 1 -Because "$file must define $key exactly once"
                $nodes[0].value | Should -Not -BeNullOrEmpty -Because "$key must be visible text"
                $nodes[0].GetAttribute('space', 'http://www.w3.org/XML/1998/namespace') |
                    Should -Be 'preserve' -Because "$key must preserve resource whitespace"
            }
        }
    }

    It 'does not leave the final toggle copy in English for non-English locales' {
        $english = Read-ResourceXml (Join-Path $appRoot 'en-US\Resources.resw')
        $titleKey = 'FreOverlay_ShowTokenUsageAndCostLabel.Text'
        $descriptionKey = 'FreOverlay_ShowTokenUsageAndCostDescription.Text'
        $englishTitle = Get-ResourceValue $english $titleKey
        $englishDescription = Get-ResourceValue $english $descriptionKey

        foreach ($directory in Get-ChildItem $appRoot -Directory) {
            if ($directory.Name -in @('en-US', 'en-GB') + $pseudoLocales) { continue }
            $xml = Read-ResourceXml (Join-Path $directory.FullName 'Resources.resw')
            (Get-ResourceValue $xml $titleKey) |
                Should -Not -Be $englishTitle -Because "$($directory.Name) needs a localized title"
            (Get-ResourceValue $xml $descriptionKey) |
                Should -Not -Be $englishDescription -Because "$($directory.Name) needs a localized description"
        }
    }

    It 'keeps FRE and Settings copy aligned in every shared locale' {
        $keyPairs = @(
            @('FreOverlay_ShowTokenUsageAndCostLabel.Text', 'AIAgents_ShowTokenUsageAndCost.Header'),
            @('FreOverlay_ShowTokenUsageAndCostDescription.Text', 'AIAgents_ShowTokenUsageAndCost.HelpText')
        )

        foreach ($directory in Get-ChildItem $settingsRoot -Directory) {
            $appXml = Read-ResourceXml (Join-Path $appRoot "$($directory.Name)\Resources.resw")
            $settingsXml = Read-ResourceXml (Join-Path $directory.FullName 'Resources.resw')
            foreach ($pair in $keyPairs) {
                (Get-ResourceValue $settingsXml $pair[1]) |
                    Should -Be (Get-ResourceValue $appXml $pair[0]) -Because "$($directory.Name) FRE and Settings copy must match"
            }
        }
    }

    It 'keeps pseudo-locales on the English fallback and allows tokens to be translated' {
        $english = Read-ResourceXml (Join-Path $appRoot 'en-US\Resources.resw')
        foreach ($locale in $pseudoLocales) {
            $pseudo = Read-ResourceXml (Join-Path $appRoot "$locale\Resources.resw")
            foreach ($key in $appKeys) {
                (Get-ResourceValue $pseudo $key) | Should -Be (Get-ResourceValue $english $key)
            }
        }

        $tokenNode = $english.SelectSingleNode("/root/data[@name='Usage_TokensUnit']")
        $tokenNode.comment | Should -Not -Match '\{Locked'
    }
}
