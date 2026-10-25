#!/bin/bash
set -e

# Dossier contenant le RPM Oracle 23.26 (26ai) EE deja telecharge (a adapter)
RPM_DIR="/root/oracle_rpms"
RPM_FILE=$(ls "$RPM_DIR"/oracle-database-ee-23ai-*.rpm | head -1)

sudo dnf -y localinstall "$RPM_FILE"

# ORACLE_BASE/ORACLE_HOME par convention RPM (A VERIFIER juste apres install, moins certain
# que pour la 19c : rpm -ql <nom_du_package> | grep dbhome_1, ou cat /etc/oratab)
echo "ORACLE_BASE attendu : /opt/oracle"
echo "ORACLE_HOME attendu : /opt/oracle/product/23ai/dbhome_1"
ls -d /opt/oracle/product/23ai/dbhome_1 2>/dev/null || echo "Chemin different - verifier avec: rpm -ql \$(rpm -qa | grep oracle-database-ee) | grep dbhome_1"
