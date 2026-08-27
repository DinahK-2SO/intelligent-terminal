[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ReadyPath,
    [Parameter(Mandatory)][string]$EventPath
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

function Write-ProbeEvent {
    param(
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][hashtable]$Data
    )

    $record = [ordered]@{
        type = $Type
        at = [DateTime]::UtcNow.ToString('o')
    }
    foreach ($entry in $Data.GetEnumerator()) {
        $record[$entry.Key] = $entry.Value
    }
    Add-Content -LiteralPath $EventPath -Value ($record | ConvertTo-Json -Compress) -Encoding utf8
}

$form = [System.Windows.Forms.Form]::new()
$form.Text = "Local TDD input probe $PID"
$form.Name = 'LocalTddInputProbe'
$form.ClientSize = [System.Drawing.Size]::new(480, 320)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.Location = [System.Drawing.Point]::new(160, 160)
$form.KeyPreview = $true

$form.add_MouseDown({
    param($sender, $eventArgs)
    Write-ProbeEvent -Type 'mouse-down' -Data @{
        button = [string]$eventArgs.Button
        clicks = $eventArgs.Clicks
        x = $eventArgs.X
        y = $eventArgs.Y
    }
})
$form.add_MouseUp({
    param($sender, $eventArgs)
    Write-ProbeEvent -Type 'mouse-up' -Data @{
        button = [string]$eventArgs.Button
        clicks = $eventArgs.Clicks
        x = $eventArgs.X
        y = $eventArgs.Y
    }
})
$form.add_KeyDown({
    param($sender, $eventArgs)
    Write-ProbeEvent -Type 'key-down' -Data @{
        key = [string]$eventArgs.KeyCode
        alt = $eventArgs.Alt
        control = $eventArgs.Control
        shift = $eventArgs.Shift
    }
})
$form.add_Shown({
    @{
        pid = $PID
        hwnd = $form.Handle.ToInt64()
        title = $form.Text
        clientWidth = $form.ClientSize.Width
        clientHeight = $form.ClientSize.Height
    } | ConvertTo-Json | Set-Content -LiteralPath $ReadyPath -Encoding utf8
    $form.Activate()
})

[System.Windows.Forms.Application]::Run($form)