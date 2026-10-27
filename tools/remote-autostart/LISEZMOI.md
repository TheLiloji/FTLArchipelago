# Lancer les Remote Control automatiquement

Un petit outil, `claude-rc`, qui lance un `claude remote-control` par dossier, le relance s'il tombe, et démarre tout seul à l'ouverture de session. La liste des dossiers est dans un fichier texte, une ligne par dossier. Une session Claude locale peut s'y ajouter elle-même avec une commande.

Format de la liste (`dossiers.conf`) :

```text
nom | dossier | options facultatives
ftl | /home/zacchariebernard/DEV/ftl-archipelago
```

Le nom apparaît dans la liste des sessions sur claude.ai/code. Les options sont celles de `claude remote-control` (par exemple `--permission-mode auto` ou `--capacity 4`). Par défaut l'outil ajoute `--no-create-session-in-dir` : sans ça, chaque relance laisserait une session vide de plus dans la liste. Tu peux toujours ouvrir une nouvelle session sur ce dossier depuis claude.ai/code ou l'appli.

## Avant d'installer (les deux machines)

1. Arrête le `claude remote-control` que tu lances à la main dans ces dossiers, sinon il y en aura deux sur le même dossier. Ne le fais pas pendant qu'un thread LINUX ou WINDOWS-TESTS travaille.
2. Il faut que chaque dossier ait déjà été lancé une fois à la main avec `claude remote-control`, pour avoir répondu `y` à "Trust ce dossier" et à "Enable Remote Control". Si ce n'est pas fait, l'outil l'affiche dans sa fenêtre et tu peux répondre dedans (voir "Voir une fenêtre").

## Linux (Zacctuxedo)

Copie le dossier `linux/` sur le PC, puis :

```text
sudo apt install tmux        # seulement s'il manque
cd linux
bash install.sh
```

Ça installe `~/.local/bin/claude-rc`, la liste dans `~/.config/claude-rc/dossiers.conf` et trois services systemd utilisateur. Ils démarrent à l'ouverture de session. Quand la liste change, les nouvelles lignes sont lancées toutes seules dans la seconde. Rien ne touche aux dossiers du home.

Commandes utiles :

```text
claude-rc status                 # ce qui tourne
claude-rc add fabrique /home/terensys/FABRIQUE_INTERFACES
claude-rc remove fabrique
claude-rc restart ftl            # relancer une entrée
claude-rc stop                   # tout arrêter (jusqu'à la prochaine session ou "claude-rc start")
claude-rc attach ftl             # voir la fenêtre (Ctrl+b puis d pour en sortir sans l'arrêter)
```

Chaque `claude remote-control` tourne dans sa session tmux, sur un serveur tmux à part (`tmux -L claude-rc ls`), donc tes propres sessions tmux ne sont pas touchées. Journal des relances : `~/.local/state/claude-rc/<nom>.log`.

La liste fournie contient aussi FABRIQUE_INTERFACES.

Si des `claude remote-control` tournent déjà à la main, `bash install.sh --later` installe sans rien lancer : tout démarre à la prochaine ouverture de session.

Pour tout désinstaller :

```text
systemctl --user disable --now claude-rc.service claude-rc-sync.path
rm ~/.config/systemd/user/claude-rc*.service ~/.config/systemd/user/claude-rc-sync.path ~/.local/bin/claude-rc
```

## Windows (Alfred_bipboup)

Copie le dossier `windows\` sur le PC, puis dans PowerShell (pas besoin d'admin en principe) :

```text
cd <le dossier windows copié>
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Ça copie tout dans `%USERPROFILE%\claude-rc\` et crée la tâche planifiée `claude-rc`. Elle lance tout à l'ouverture de session, puis revérifie toutes les 5 minutes : elle relance ce qui manque et prend les nouvelles lignes. Elle tourne sans fenêtre, donc rien ne vole le focus pendant que tu joues. Chaque `claude remote-control` tourne dans sa propre fenêtre PowerShell réduite, nommée `claude-rc <nom>` ; la fermer arrête l'entrée jusqu'à la prochaine vérification.

Commandes utiles (dans PowerShell) :

```text
$rc = "$env:USERPROFILE\claude-rc\claude-rc.ps1"
powershell -ExecutionPolicy Bypass -File $rc status
powershell -ExecutionPolicy Bypass -File $rc add autre "C:\chemin\du\dossier"
powershell -ExecutionPolicy Bypass -File $rc remove autre
powershell -ExecutionPolicy Bypass -File $rc restart
powershell -ExecutionPolicy Bypass -File $rc stop
```

Journal des relances : `%USERPROFILE%\claude-rc\logs\<nom>.log`. Si la création de la tâche est refusée, relance `install.ps1` dans un PowerShell ouvert en administrateur. Pour désinstaller : `Unregister-ScheduledTask -TaskName claude-rc`, puis `stop` et supprimer le dossier `%USERPROFILE%\claude-rc`.

## TRAZYN (en option)

Le script Linux marche aussi sur le serveur (dossier `/home/zacc/trazyn-claude`). Sur un serveur sans session ouverte, il faut en plus `loginctl enable-linger zacc` pour que les services utilisateur démarrent au boot. À faire seulement avec ton accord, comme tout ce qui touche à TRAZYN.

## Pour les sessions Claude locales

Le bloc à ajouter au CLAUDE.md de chaque machine est dans `CLAUDE-snippet.md`. Il dit à Claude comment ajouter son dossier à la liste.

## Ce qu'il faut savoir

- Si le réseau est coupé plus de 10 minutes environ, `claude remote-control` s'arrête de lui-même ; l'outil le relance 30 secondes après. Ça crée une nouvelle session côté claude.ai, l'ancienne reste dans l'historique.
- Si l'erreur "too many sessions" revient, regarde `claude-rc status` : il ne doit y avoir qu'une entrée par dossier, et pas de `claude remote-control` lancé à la main en plus.
- Les scripts ne contiennent aucun secret : ils utilisent la connexion Claude déjà faite sur la machine.
