#!/bin/bash
# Lance netca/dbca/lsnrctl en tant que user "oracle" (jamais en root), via sudo -u oracle.
set -e

ORACLE_BASE="/opt/oracle"
ORACLE_HOME="/opt/oracle/product/19.3.0/dbhome_1"
ORACLE_SID="ora19"
DB_PASSWORD="password1234"   # sys / system identiques
LISTENER_PORT=1521

sudo -u oracle -i bash <<EOF
set -e
export ORACLE_BASE="$ORACLE_BASE"
export ORACLE_HOME="$ORACLE_HOME"
export ORACLE_SID="$ORACLE_SID"
export ORACLE_HOSTNAME=\$(hostname -s)
export PATH="\$ORACLE_HOME/bin:\$PATH"

mkdir -p "\$ORACLE_BASE/oradata" "\$ORACLE_BASE/fast_recovery_area" "\$ORACLE_BASE/response"

# ---- 1. Listener via netca (meme outil/syntaxe que sur Windows, template officiel valide) ----
cat > "\$ORACLE_BASE/response/netca.rsp" <<RSP
[GENERAL]
RESPONSEFILE_VERSION="19.0"
CREATE_TYPE="CUSTOM"

[oracle.net.ca]
INSTALLED_COMPONENTS={"server","net8","javavm"}
INSTALL_TYPE=""typical""
LISTENER_NUMBER=1
LISTENER_NAMES={"LISTENER"}
LISTENER_PROTOCOLS={"TCP;$LISTENER_PORT"}
LISTENER_START=""LISTENER""
NAMING_METHODS={"TNSNAMES","ONAMES","HOSTNAME"}
NSN_NUMBER=1
NSN_NAMES={"EXTPROC_CONNECTION_DATA"}
NSN_SERVICE={"PLSExtProc"}
NSN_PROTOCOLS={"TCP;HOSTNAME;1521"}
RSP

netca -silent -responsefile "\$ORACLE_BASE/response/netca.rsp"

# ---- 2. Base de donnees (standalone = non-CDB, General Purpose, memoire auto simple) ----
dbca -silent -createDatabase \\
  -templateName General_Purpose.dbc \\
  -gdbname $ORACLE_SID \\
  -sid $ORACLE_SID \\
  -createAsContainerDatabase false \\
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
