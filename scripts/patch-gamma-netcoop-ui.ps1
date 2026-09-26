param(
    [Parameter(Mandatory = $true)]
    [string]$RuntimeRoot
)

$ErrorActionPreference = 'Stop'
$runtime = (Resolve-Path -LiteralPath $RuntimeRoot).Path
$latin1 = [System.Text.Encoding]::GetEncoding(28591)

function Replace-Exact {
    param([string]$File, [string]$Old, [string]$New)
    if (-not (Test-Path -LiteralPath $File)) { return }
    $bytes = [System.IO.File]::ReadAllBytes($File)
    $content = $latin1.GetString($bytes)
    if ($content.Contains($New)) { return }
    if (-not $content.Contains($Old)) { throw "Expected GAMMA script text missing: $File" }
    $updated = $content.Replace($Old, $New)
    [System.IO.File]::WriteAllBytes($File, $latin1.GetBytes($updated))
    Write-Host "Patched $File"
}

foreach ($scriptRoot in @('client\scripts', 'gamedata\scripts')) {
    $options = Join-Path $runtime "$scriptRoot\ui_options.script"
    Replace-Exact $options 'local se_actor = alife():actor()' 'local sim = alife()`n`tlocal se_actor = sim and sim:actor()'.Replace('`n', "`n").Replace('`t', "`t")
    Replace-Exact $options 'return alife():actor():character_name()' 'local sim = alife()`n`tlocal se_actor = sim and sim:actor()`n`tlocal actor = db.actor`n`treturn (se_actor and se_actor:character_name()) or (actor and actor:character_name()) or ""'.Replace('`n', "`n").Replace('`t', "`t")

    foreach ($name in @('ui_inventory.script', 'ui_companion_inv.script')) {
        Replace-Exact (Join-Path $runtime "$scriptRoot\$name") 'alife():actor():character_name()' 'db.actor:character_name()'
    }
}
