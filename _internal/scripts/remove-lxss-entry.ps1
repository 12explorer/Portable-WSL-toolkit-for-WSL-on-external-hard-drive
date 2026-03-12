param(
    [Parameter(Mandatory = $true)]
    [string]$DistributionName,

    [Parameter(Mandatory = $true)]
    [string]$BasePath
)

$ErrorActionPreference = 'Stop'

try {
    $items = Get-ChildItem -LiteralPath 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue
    $match = $items |
        Where-Object {
            try {
                $item = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop
                $item.DistributionName -eq $DistributionName -and $item.BasePath -eq $BasePath
            }
            catch {
                $false
            }
        } |
        Select-Object -First 1

    if (-not $match) {
        exit 1
    }

    Remove-Item -LiteralPath $match.PSPath -Recurse -Force
    exit 0
}
catch {
    exit 2
}