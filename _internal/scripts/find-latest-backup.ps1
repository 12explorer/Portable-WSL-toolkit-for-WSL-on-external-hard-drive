param(
    [Parameter(Mandatory = $true)]
    [string]$Directory,

    [Parameter(Mandatory = $true)]
    [string]$Distro
)

$ErrorActionPreference = 'SilentlyContinue'

if (Test-Path -LiteralPath $Directory) {
    Get-ChildItem -LiteralPath $Directory -File -Filter ($Distro + '_*.tar') |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 |
        ForEach-Object { $_.FullName }
}