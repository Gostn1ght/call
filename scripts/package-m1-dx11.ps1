param(
    [Parameter(Mandatory = $true)] [string] $BuildBin,
    [Parameter(Mandatory = $true)] [string] $DestinationRoot,
    [string] $DependencyBin
)

$ErrorActionPreference = 'Stop'
$sourceExe = Join-Path $BuildBin 'AnomalyDX11.exe'
if (-not (Test-Path -LiteralPath $sourceExe -PathType Leaf)) {
    throw "DX11 executable missing: $sourceExe"
}

$serverBin = Join-Path $DestinationRoot 'dedicated'
$clientBin = Join-Path $DestinationRoot 'bin'
New-Item -ItemType Directory -Force -Path $serverBin, $clientBin | Out-Null

Copy-Item -LiteralPath $sourceExe -Destination (Join-Path $serverBin 'AnomalyGammaNetServerDX11.exe') -Force
Copy-Item -LiteralPath $sourceExe -Destination (Join-Path $clientBin 'AnomalyGammaNetClientDX11.exe') -Force

foreach ($dependencySource in @($BuildBin, $DependencyBin)) {
    if (-not $dependencySource) { continue }
    Get-ChildItem -LiteralPath $dependencySource -Filter '*.dll' -File | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $serverBin -Force
        Copy-Item -LiteralPath $_.FullName -Destination $clientBin -Force
    }
}

Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $serverBin 'AnomalyGammaNetServerDX11.exe'), (Join-Path $clientBin 'AnomalyGammaNetClientDX11.exe') |
    Select-Object Path, Hash
