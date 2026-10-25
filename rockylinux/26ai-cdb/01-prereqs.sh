#!/bin/bash
set -e

# Repo public Oracle Linux, repo "appstream" sur OL10.
# Rebranding 26ai : le paquet s'appelle oracle-ai-database-preinstall-26ai (pas "23ai").
sudo dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL10/appstream/x86_64/ --id=oracle
sudo dnf config-manager --save --setopt=oracle.gpgcheck=0
sudo dnf clean all && sudo dnf makecache
sudo dnf install -y oracle-ai-database-preinstall-26ai unzip
# Pas de mot de passe sur le compte oracle : acces uniquement via root/sudoers (sudo -u oracle -i).

sudo setenforce 0 || true
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
sudo systemctl stop firewalld
sudo systemctl disable firewalld
