param(
    [Parameter(Mandatory = $true)]
    [string]$Directory,

    [Parameter(Mandatory = $true)]
    [string]$Distro,

    [int]$Keep = 5
)

$ErrorActionPreference = 'SilentlyContinue'

Get-ChildItem -LiteralPath $Directory -File -Filter ($Distro + '_*.tar') |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $Keep |
    Remove-Item -Force

exit 0