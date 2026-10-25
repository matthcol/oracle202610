#!/bin/bash
# A lancer avec un user sudo (pas besoin d'etre deja root, le script sudo chaque commande qui l'exige).
set -e

# Repo public Oracle Linux (compatible Rocky, binairement proche de RHEL) : requis car
# oracle-database-preinstall-19c n'est pas dans les repos Rocky par defaut.
sudo dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64/
sudo dnf install -y oracle-database-preinstall-19c unzip
# Le RPM preinstall cree le user/groupes oracle (oinstall/dba), regle sysctl, limits.conf, etc.
# Pas de mot de passe sur le compte oracle : acces uniquement via root/sudoers (sudo -u oracle -i).

# Lab de formation : SELinux permissif + firewall desactive (pas adapte a de la prod)
sudo setenforce 0 || true
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
sudo systemctl stop firewalld
sudo systemctl disable firewalld
