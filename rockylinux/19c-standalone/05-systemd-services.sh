#!/bin/bash
# Cree et active les services systemd pour le listener et l'instance
# (demarrage/arret automatique avec la VM). A lancer apres 03-create-database.sh.
set -e

ORACLE_HOME="/oracle/product/19.3.0/dbhome_1"
ORACLE_SID="ora19"

# dbstart/dbshut ne demarrent que les instances marquees "Y" dans /etc/oratab
sudo sed -i "s|^$ORACLE_SID:$ORACLE_HOME:N|$ORACLE_SID:$ORACLE_HOME:Y|" /etc/oratab
grep "^$ORACLE_SID:" /etc/oratab

sudo tee /etc/systemd/system/oracle-listener.service > /dev/null <<EOF
[Unit]
Description=Oracle Net Listener
After=network.target

[Service]
Type=forking
User=oracle
Group=oinstall
Environment=ORACLE_HOME=$ORACLE_HOME
ExecStart=$ORACLE_HOME/bin/lsnrctl start
ExecStop=$ORACLE_HOME/bin/lsnrctl stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/oracle-database.service > /dev/null <<EOF
[Unit]
Description=Oracle Database instance ($ORACLE_SID)
After=network.target oracle-listener.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=oracle
Group=oinstall
Environment=ORACLE_HOME=$ORACLE_HOME
ExecStart=$ORACLE_HOME/bin/dbstart $ORACLE_HOME
ExecStop=$ORACLE_HOME/bin/dbshut $ORACLE_HOME

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable oracle-listener.service oracle-database.service
sudo systemctl start oracle-listener.service
sudo systemctl start oracle-database.service

sudo systemctl status oracle-listener.service oracle-database.service --no-pager
