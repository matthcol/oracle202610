#!/bin/bash
set -e

# Repo public Oracle Linux (compatible Rocky, binairement proche de RHEL) : requis car
# oracle-database-preinstall-23ai n'est pas dans les repos Rocky par defaut.
# NOTE: a verifier - le nom exact du paquet peut differer, et il est possible qu'il faille
# le chemin "addons" plutot que "baseos" :
#   sudo dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL10/addons/x86_64/
sudo dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL10/baseos/latest/x86_64/
sudo dnf install -y oracle-database-preinstall-23ai unzip
# Pas de mot de passe sur le compte oracle : acces uniquement via root/sudoers (sudo -u oracle -i).

sudo setenforce 0 || true
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
sudo systemctl stop firewalld
sudo systemctl disable firewalld
