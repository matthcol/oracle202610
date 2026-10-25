#!/bin/bash
# Cree la base via dbca. A lancer APRES 03-create-listener.sh (le listener doit deja exister).
set -e

ORACLE_BASE="/oracle"
ORACLE_HOME="/oracle/product/23.26.0/dbhome_1"
ORACLE_SID="ora26"
PDB_NAME="dbmovie"
DB_PASSWORD="password1234"   # sys / system / pdbadmin identiques
ORADATA="/oradata"

sudo mkdir -p "$ORADATA"
sudo chown oracle:oinstall "$ORADATA"

sudo -u oracle -i bash <<EOF
set -e
export ORACLE_BASE="$ORACLE_BASE"
export ORACLE_HOME="$ORACLE_HOME"
export ORACLE_SID="$ORACLE_SID"
export ORACLE_HOSTNAME=\$(hostname -s)
export PATH="\$ORACLE_HOME/bin:\$PATH"

mkdir -p "\$ORACLE_BASE/fast_recovery_area"

dbca -silent -createDatabase \\
  -templateName General_Purpose.dbc \\
  -gdbname $ORACLE_SID \\
  -sid $ORACLE_SID \\
  -createAsContainerDatabase true \\
  -numberOfPDBs 1 \\
  -pdbName $PDB_NAME \\
  -pdbAdminPassword $DB_PASSWORD \\
  -useLocalUndoForPDBs true \\
  -databaseType MULTIPURPOSE \\
  -characterSet AL32UTF8 \\
  -memoryPercentage 40 \\
  -emConfiguration NONE \\
  -datafileDestination "$ORADATA" \\
  -recoveryAreaDestination "\$ORACLE_BASE/fast_recovery_area" \\
  -storageType FS \\
  -listeners LISTENER \\
  -sysPassword $DB_PASSWORD \\
  -systemPassword $DB_PASSWORD \\
  -sampleSchema false \\
  -ignorePreReqs
EOF
