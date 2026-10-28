#!/bin/bash
# Cree la base via dbca. A lancer APRES 03-create-listener.sh (le listener doit deja exister).
set -e

ORACLE_BASE="/oracle"
ORACLE_HOME="/oracle/product/19.3.0/dbhome_1"
ORACLE_SID="ora19"
DB_PASSWORD="password1234"   # sys / system identiques
ORADATA="/oradata"
FRA="/orabackup/fast_recovery_area"
FRA_SIZE="5G"

sudo mkdir -p "$ORADATA" "$FRA"
sudo chown oracle:oinstall "$ORADATA" "$FRA"

sudo -u oracle -i bash <<EOF
set -e
export ORACLE_BASE="$ORACLE_BASE"
export ORACLE_HOME="$ORACLE_HOME"
export ORACLE_SID="$ORACLE_SID"
export ORACLE_HOSTNAME=\$(hostname -s)
export PATH="\$ORACLE_HOME/bin:\$PATH"

dbca -silent -createDatabase \\
  -templateName General_Purpose.dbc \\
  -gdbname $ORACLE_SID \\
  -sid $ORACLE_SID \\
  -createAsContainerDatabase false \\
  -databaseType MULTIPURPOSE \\
  -characterSet AL32UTF8 \\
  -memoryPercentage 40 \\
  -emConfiguration NONE \\
  -datafileDestination "$ORADATA" \\
  -recoveryAreaDestination "$FRA" \\
  -storageType FS \\
  -listeners LISTENER \\
  -sysPassword $DB_PASSWORD \\
  -systemPassword $DB_PASSWORD \\
  -sampleSchema false \\
  -initParams "db_recovery_file_dest_size=$FRA_SIZE" \\
  -ignorePreReqs
EOF
