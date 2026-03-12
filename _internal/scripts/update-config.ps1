param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigFile,

    [Parameter(Mandatory = $true)]
    [string]$SettingName,

    [Parameter(Mandatory = $true)]
    [string]$SettingValue
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ConfigFile)) {
    exit 4
}

$lines = Get-Content -LiteralPath $ConfigFile
$pattern = '^set "' + [regex]::Escape($SettingName) + '=.*"$'
$replacement = 'set "' + $SettingName + '=' + $SettingValue + '"'
$updated = $false

$newLines = foreach ($line in $lines) {
    if ($line -match $pattern) {
        $updated = $true
        $replacement
    }
    else {
        $line
    }
}

if (-not $updated) {
    $newLines += $replacement
}

Set-Content -LiteralPath $ConfigFile -Value $newLines -Encoding ASCII
exit 0