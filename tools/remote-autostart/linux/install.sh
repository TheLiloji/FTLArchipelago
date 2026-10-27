#!/usr/bin/env bash
# Installe claude-rc pour l'utilisateur courant (aucun sudo, sauf pour tmux s'il manque).
# bash install.sh --later : installe sans rien lancer, démarrage à la prochaine session.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"

command -v tmux >/dev/null || { echo "tmux manque : sudo apt install tmux, puis relance ce script"; exit 1; }
command -v claude >/dev/null || [ -x "$HOME/.local/bin/claude" ] || { echo "claude introuvable dans le PATH"; exit 1; }

mkdir -p "$HOME/.local/bin" "$HOME/.config/claude-rc" "$HOME/.config/systemd/user"
install -m 755 "$here/claude-rc" "$HOME/.local/bin/claude-rc"
if [ -f "$HOME/.config/claude-rc/dossiers.conf" ]; then
  echo "dossiers.conf existe déjà, je le garde"
else
  cp "$here/dossiers.conf" "$HOME/.config/claude-rc/dossiers.conf"
fi
cp "$here/claude-rc.service" "$here/claude-rc-sync.service" "$here/claude-rc-sync.path" "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
if [ "${1:-}" = "--later" ]; then
  # Rien n'est lancé maintenant : utile quand des remote-control tournent déjà à la main.
  systemctl --user enable claude-rc.service claude-rc-sync.path
  echo "Installé. Tout démarrera à la prochaine ouverture de session."
else
  systemctl --user enable --now claude-rc.service claude-rc-sync.path
fi
"$HOME/.local/bin/claude-rc" status
