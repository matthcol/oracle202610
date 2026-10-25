#!/bin/bash
# Configure l'environnement Oracle (ORACLE_SID/ORACLE_HOME via oraenv) au login,
# pour le user oracle et pour l'admin (srvadmin). Idempotent.
set -e

ORACLE_SID="ora19"
ADMIN_USER="srvadmin"

for USR in oracle "$ADMIN_USER"; do
  HOME_DIR=$(getent passwd "$USR" | cut -d: -f6)
  USR_GROUP=$(id -gn "$USR")

  sudo mkdir -p "$HOME_DIR/.bashrc.d"

  sudo tee "$HOME_DIR/.bashrc.d/oracle-env.sh" > /dev/null <<EOF
export ORACLE_SID=$ORACLE_SID
export ORAENV_ASK=NO
. /usr/local/bin/oraenv > /dev/null
unset ORAENV_ASK
EOF
  sudo chown "$USR:$USR_GROUP" "$HOME_DIR/.bashrc.d/oracle-env.sh"

  # S'assure que .bashrc.d/ est bien source depuis .bashrc (ajoute seulement si absent)
  if ! grep -q "bashrc.d" "$HOME_DIR/.bashrc" 2>/dev/null; then
    sudo tee -a "$HOME_DIR/.bashrc" > /dev/null <<'EOF'

if [ -d ~/.bashrc.d ]; then
  for f in ~/.bashrc.d/*.sh; do [ -r "$f" ] && . "$f"; done
fi
EOF
    sudo chown "$USR:$USR_GROUP" "$HOME_DIR/.bashrc"
  fi

  echo "OK : $USR (SID=$ORACLE_SID)"
done
