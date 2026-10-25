#!/bin/bash
# Installe le LOGICIEL Oracle 26ai depuis le zip (comme sous Windows), pas via le RPM complet.
# Le RPM preinstall (01-prereqs.sh) a deja cree le user/groupes oracle et les prerequis systeme.
set -e

# /root est illisible pour tout le monde sauf root (meme pas le user oracle) : on utilise
# un repertoire dedie, lisible par tous, pour y deposer le zip.
ZIP_DIR="/opt/install_zips"
sudo mkdir -p "$ZIP_DIR"
sudo chmod 755 "$ZIP_DIR"
ZIP_FILE=$(ls "$ZIP_DIR"/LINUX.X64_23*_db_home.zip | head -1)

ORACLE_BASE="/oracle"
ORACLE_HOME="/oracle/product/23.26.0/dbhome_1"

sudo mkdir -p "$ORACLE_HOME"
sudo chown -R oracle:oinstall "$ORACLE_BASE"

sudo -u oracle -i bash <<EOF
set -e
export ORACLE_BASE="$ORACLE_BASE"
export ORACLE_HOME="$ORACLE_HOME"

unzip -oq "$ZIP_FILE" -d "\$ORACLE_HOME"

cat > /tmp/db_install.rsp <<RSP
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=\$ORACLE_BASE/oraInventory
ORACLE_BASE=\$ORACLE_BASE
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=oper
oracle.install.db.OSBACKUPDBA_GROUP=backupdba
oracle.install.db.OSDGDBA_GROUP=dgdba
oracle.install.db.OSKMDBA_GROUP=kmdba
oracle.install.db.OSRACDBA_GROUP=racdba
oracle.install.db.isRACOneInstall=false
DECLINE_SECURITY_UPDATES=true
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
RSP

"\$ORACLE_HOME/runInstaller" -silent -ignorePrereqFailure -waitforcompletion -responseFile /tmp/db_install.rsp
EOF

# ---- Scripts root demandes par OUI en fin d'install silencieux ----
sudo "$ORACLE_BASE/oraInventory/orainstRoot.sh"
sudo "$ORACLE_HOME/root.sh"
