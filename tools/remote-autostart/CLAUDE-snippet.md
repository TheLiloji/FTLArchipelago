## Remote Control automatique (claude-rc)

Les `claude remote-control` de cette machine sont lancés par `claude-rc`, à partir d'une liste de dossiers (une ligne `nom | dossier | options`). Pour qu'un nouveau dossier soit accessible à distance, ajoute-le, ne lance pas `claude remote-control` à la main :

- Linux : `claude-rc add <nom> <dossier>` (liste : `~/.config/claude-rc/dossiers.conf`, état : `claude-rc status`)
- Windows : `powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\claude-rc\claude-rc.ps1" add <nom> "<dossier>"` (liste : `%USERPROFILE%\claude-rc\dossiers.conf`)

Le nom : lettres, chiffres, - et _. Ne fais jamais `stop` ou `restart` sur l'entrée qui fait tourner ta propre session : ça te coupe. Ne retire pas d'entrée sans l'accord de Zaccharie.
