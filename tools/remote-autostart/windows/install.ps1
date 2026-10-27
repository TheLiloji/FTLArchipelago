# Installe claude-rc pour l'utilisateur courant : copie dans %USERPROFILE%\claude-rc
# et crée une tâche planifiée "claude-rc" qui lance tout à l'ouverture de session,
# puis revérifie toutes les 5 minutes (relance ce qui manque, prend les nouvelles lignes).
# install.ps1 -Later : crée la tâche sans rien lancer maintenant (démarrage à la prochaine session).
param([switch]$Later)
$ErrorActionPreference = 'Stop'
$dest = Join-Path $env:USERPROFILE 'claude-rc'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'claude-rc.ps1') -Destination $dest -Force
$conf = Join-Path $dest 'dossiers.conf'
if (Test-Path -LiteralPath $conf) { Write-Output 'dossiers.conf existe déjà, je le garde' }
else { Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'dossiers.conf') -Destination $conf }

$script = Join-Path $dest 'claude-rc.ps1'
# conhost --headless : aucune fenêtre ne clignote toutes les 5 minutes (pas de vol de focus en jeu).
$action = New-ScheduledTaskAction -Execute 'conhost.exe' `
    -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$script`" start"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$trigger.Repetition = (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)).Repetition
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'claude-rc' -Action $action -Trigger $trigger -Settings $settings `
    -Principal $principal -Description 'Lance claude remote-control pour chaque ligne de dossiers.conf' -Force | Out-Null
Write-Output "Tâche planifiée claude-rc créée. Script et config dans $dest"
if ($Later) { Write-Output 'Rien lancé maintenant : tout démarrera à la prochaine ouverture de session.' }
else { & $script start }
