#!/bin/bash
# Cree et demarre le listener via netca. Peut etre relance seul en cas d'echec
# (idempotent : repart propre si listener.ora existe deja), sans avoir a refaire dbca.
set -e

ORACLE_BASE="/oracle"
ORACLE_HOME="/oracle/product/19.3.0/dbhome_1"
LISTENER_PORT=1521

sudo -u oracle -i bash <<EOF
set -e
export ORACLE_BASE="$ORACLE_BASE"
export ORACLE_HOME="$ORACLE_HOME"
export ORACLE_HOSTNAME=\$(hostname -s)
export PATH="\$ORACLE_HOME/bin:\$PATH"

mkdir -p "\$ORACLE_BASE/response"
rm -f "\$ORACLE_HOME/network/admin/listener.ora"

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
EOF
