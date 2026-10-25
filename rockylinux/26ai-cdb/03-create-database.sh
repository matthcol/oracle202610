#!/bin/bash
# Lance netca/dbca/lsnrctl en tant que user "oracle" (jamais en root), via sudo -u oracle.
set -e

ORACLE_BASE="/opt/oracle"
ORACLE_HOME="/opt/oracle/product/23ai/dbhome_1"
ORACLE_SID="ora26"
PDB_NAME="dbmovie"
DB_PASSWORD="password1234"   # sys / system / pdbadmin identiques
LISTENER_PORT=1521

sudo -u oracle -i bash <<EOF
set -e
export ORACLE_BASE="$ORACLE_BASE"
export ORACLE_HOME="$ORACLE_HOME"
export ORACLE_SID="$ORACLE_SID"
export PATH="\$ORACLE_HOME/bin:\$PATH"

mkdir -p "\$ORACLE_BASE/oradata" "\$ORACLE_BASE/fast_recovery_area"

# ---- 1. Listener (HOST=0.0.0.0 : evite tout souci si le hostname de la VM change plus tard) ----
cat > "\$ORACLE_HOME/network/admin/listener.ora" <<LSNR
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
LSNR
lsnrctl start

# ---- 2. Base de donnees (CDB obligatoire depuis la 23ai, PDB dbmovie, memoire auto simple) ----
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
  -datafileDestination "\$ORACLE_BASE/oradata" \\
  -recoveryAreaDestination "\$ORACLE_BASE/fast_recovery_area" \\
  -storageType FS \\
  -listeners LISTENER \\
  -sysPassword $DB_PASSWORD \\
  -systemPassword $DB_PASSWORD \\
  -sampleSchema false \\
  -ignorePreReqs
EOF
