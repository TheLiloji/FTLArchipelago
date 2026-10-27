# claude-rc : lance un "claude remote-control" par dossier listé dans dossiers.conf,
# chacun dans sa fenêtre PowerShell réduite, avec relance automatique s'il s'arrête.
#
#   claude-rc.ps1 start                     lance ce qui manque (sans toucher à ce qui tourne)
#   claude-rc.ps1 stop [nom]                arrête tout, ou une seule entrée
#   claude-rc.ps1 restart [nom]             arrête puis relance
#   claude-rc.ps1 status                    état de chaque entrée
#   claude-rc.ps1 add <nom> <dossier> [options...]   ajoute une entrée puis la lance
#   claude-rc.ps1 remove <nom>              retire une entrée et l'arrête
#   claude-rc.ps1 list                      affiche la config
#
# Config : dossiers.conf à côté de ce script, une ligne par dossier :
#   nom | dossier | options facultatives pour claude remote-control
param(
    [Parameter(Position = 0)][string]$Command = 'status',
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Rest = @()
)

$ErrorActionPreference = 'Stop'
$Self = $PSCommandPath
$Conf = Join-Path $PSScriptRoot 'dossiers.conf'
$LogDir = Join-Path $PSScriptRoot 'logs'
$RetryDelay = 30
# Sans session pré-créée, un redémarrage ne laisse pas de session vide en plus
# dans la liste de claude.ai/code.
$DefaultOpts = @('--no-create-session-in-dir')

$env:Path = "$env:USERPROFILE\.local\bin;$env:APPDATA\npm;$env:Path"

function Get-Entries {
    if (-not (Test-Path -LiteralPath $Conf)) { return @() }
    $list = @()
    foreach ($raw in Get-Content -LiteralPath $Conf -Encoding UTF8) {
        $line = $raw.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { continue }
        $parts = $line.Split('|')
        $name = $parts[0].Trim()
        $dir = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '' }
        $opts = if ($parts.Count -gt 2) { $parts[2].Trim() } else { '' }
        if ($name -notmatch '^[A-Za-z0-9_-]+$' -or $dir -eq '') {
            Write-Warning "ligne ignorée (format nom | dossier | options) : $line"
            continue
        }
        $list += [pscustomobject]@{ Name = $name; Dir = $dir; Opts = $opts }
    }
    return $list
}

# Les fenêtres lancées par ce script se reconnaissent à "__loop <nom>" dans leur ligne de commande.
function Get-LoopProcess([string]$Name) {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
        Where-Object { $_.CommandLine -match ('claude-rc\.ps1"?\s+__loop\s+' + [regex]::Escape($Name) + '(\s|$)') }
}

function Start-Entry($e) {
    if (Get-LoopProcess $e.Name) { Write-Output "ok      $($e.Name) (déjà lancé)"; return }
    if (-not (Test-Path -LiteralPath $e.Dir -PathType Container)) {
        Write-Output "absent  $($e.Name) : dossier $($e.Dir) introuvable"; return
    }
    $psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$Self`"", '__loop', $e.Name)
    Start-Process powershell.exe -ArgumentList $psArgs -WindowStyle Minimized | Out-Null
    Write-Output "lancé   $($e.Name) -> $($e.Dir)"
}

function Stop-Entry([string]$Name) {
    foreach ($p in @(Get-LoopProcess $Name)) {
        # /T arrête aussi claude, lancé par cette fenêtre.
        & taskkill.exe /PID $p.ProcessId /T /F | Out-Null
        Write-Output "arrêté  $Name"
    }
}

# Boucle exécutée dans la fenêtre réduite : relance claude remote-control quand il s'arrête
# (par exemple après ~10 min sans réseau, ce qui le fait quitter).
function Invoke-Loop([string]$Name) {
    $e = Get-Entries | Where-Object Name -eq $Name | Select-Object -First 1
    if (-not $e) { Write-Output "Entrée $Name absente de $Conf"; Start-Sleep 30; return }
    $host.UI.RawUI.WindowTitle = "claude-rc $Name"
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    $log = Join-Path $LogDir "$Name.log"
    $opts = @($DefaultOpts) + @($e.Opts -split '\s+' | Where-Object { $_ -ne '' })
    Set-Location -LiteralPath $e.Dir
    $ErrorActionPreference = 'Continue'
    while ($true) {
        $msg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] démarrage de $Name dans $($e.Dir)"
        Write-Output $msg; Add-Content -LiteralPath $log -Value $msg -Encoding UTF8
        & claude remote-control --name $Name @opts
        $msg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Name arrêté (code $LASTEXITCODE), relance dans ${RetryDelay}s"
        Write-Output $msg; Add-Content -LiteralPath $log -Value $msg -Encoding UTF8
        Start-Sleep -Seconds $RetryDelay
    }
}

if (-not (Test-Path -LiteralPath $Conf)) {
    Set-Content -LiteralPath $Conf -Encoding UTF8 -Value @(
        '# Un "claude remote-control" par ligne : nom | dossier | options (facultatif)',
        '# Le nom : lettres, chiffres, - et _ seulement. Lignes avec # ignorées.'
    )
}

switch ($Command) {
    '__loop' { Invoke-Loop $Rest[0] }
    'start' { foreach ($e in Get-Entries) { Start-Entry $e } }
    'stop' {
        if ($Rest.Count -ge 1) { Stop-Entry $Rest[0] }
        else { foreach ($e in Get-Entries) { Stop-Entry $e.Name } }
    }
    'restart' {
        if ($Rest.Count -ge 1) { Stop-Entry $Rest[0] } else { foreach ($e in Get-Entries) { Stop-Entry $e.Name } }
        Start-Sleep 2
        foreach ($e in Get-Entries) { Start-Entry $e }
    }
    'status' {
        foreach ($e in Get-Entries) {
            $state = if (Get-LoopProcess $e.Name) { 'lancé  ' } else { 'arrêté ' }
            Write-Output "$state $($e.Name) -> $($e.Dir)"
        }
    }
    'add' {
        if ($Rest.Count -lt 2) { throw 'usage : claude-rc.ps1 add <nom> <dossier> [options...]' }
        $name = $Rest[0]
        if ($name -notmatch '^[A-Za-z0-9_-]+$') { throw 'nom invalide : lettres, chiffres, - et _ seulement' }
        if (-not (Test-Path -LiteralPath $Rest[1] -PathType Container)) { throw "dossier introuvable : $($Rest[1])" }
        $dir = (Resolve-Path -LiteralPath $Rest[1]).Path
        if (Get-Entries | Where-Object Name -eq $name) { throw "l'entrée $name existe déjà (claude-rc.ps1 list)" }
        $opts = ($Rest | Select-Object -Skip 2) -join ' '
        Add-Content -LiteralPath $Conf -Encoding UTF8 -Value "$name | $dir | $opts"
        Write-Output "ajouté  $name -> $dir"
        foreach ($e in Get-Entries) { Start-Entry $e }
    }
    'remove' {
        if ($Rest.Count -lt 1) { throw 'usage : claude-rc.ps1 remove <nom>' }
        Stop-Entry $Rest[0]
        $keep = Get-Content -LiteralPath $Conf -Encoding UTF8 | Where-Object { $_.Split('|')[0].Trim() -ne $Rest[0] }
        Set-Content -LiteralPath $Conf -Encoding UTF8 -Value $keep
        Write-Output "retiré  $($Rest[0])"
    }
    'list' { Get-Content -LiteralPath $Conf -Encoding UTF8 }
    default { Get-Content -LiteralPath $Self -TotalCount 14 | ForEach-Object { $_ -replace '^# ?', '' } }
}
