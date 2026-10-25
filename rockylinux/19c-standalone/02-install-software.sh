#!/bin/bash
set -e

# Dossier contenant le RPM Oracle 19c EE deja telecharge (a adapter)
RPM_DIR="/root/oracle_rpms"
RPM_FILE=$(ls "$RPM_DIR"/oracle-database-ee-19c-*.rpm | head -1)

sudo dnf -y localinstall "$RPM_FILE"

# ORACLE_BASE/ORACLE_HOME sont fixes par le RPM, non personnalisables :
echo "ORACLE_BASE attendu : /opt/oracle"
echo "ORACLE_HOME attendu : /opt/oracle/product/19c/dbhome_1"
ls -d /opt/oracle/product/19c/dbhome_1
