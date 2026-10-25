#!/bin/bash
set -e

# Repo public Oracle Linux : le paquet 19c est dans "appstream" sur OL10 (confirme).
# Pour la 23ai/26ai, oracle-database-preinstall-23ai n'existe PAS ENCORE pour OL10 (verifie :
# absent du repo appstream, 404 en telechargement direct) -- probablement pas certifie sur
# cet OS trop recent. Si dnf echoue ci-dessous, utiliser 01b-prereqs-manual.sh a la place.
sudo dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL10/appstream/x86_64/ --id=oracle
sudo dnf config-manager --save --setopt=oracle.gpgcheck=0
sudo dnf clean all && sudo dnf makecache
sudo dnf install -y oracle-database-preinstall-23ai unzip
# Pas de mot de passe sur le compte oracle : acces uniquement via root/sudoers (sudo -u oracle -i).

sudo setenforce 0 || true
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
sudo systemctl stop firewalld
sudo systemctl disable firewalld
