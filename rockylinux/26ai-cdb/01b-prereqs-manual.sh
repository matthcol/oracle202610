#!/bin/bash
# Repli si oracle-database-preinstall-23ai n'est pas disponible pour votre OS (ex: OL10 au
# moment ou ce script a ete ecrit). Fait a la main ce que le RPM preinstall aurait fait :
# groupes/user oracle, parametres kernel, limites. A lancer A LA PLACE de la ligne
# "dnf install oracle-database-preinstall-23ai" dans 01-prereqs.sh si celle-ci echoue.
#
# NOTE : liste de paquets/parametres basee sur les valeurs standard documentees par Oracle
# pour 19c/23ai sur RHEL -- -ignorePreReqs est deja utilise dans 03-create-database.sh, donc
# le prereq checker de dbca rattrapera ce qui manquerait ici.
set -e

sudo dnf install -y unzip bc binutils elfutils-libelf glibc glibc-devel ksh libaio \
  libXrender libX11 libXau libgcc libnsl2 libstdc++ libxcb make \
  policycoreutils policycoreutils-python-utils smartmontools sysstat net-tools nfs-utils

# ---- Groupes et user oracle ----
sudo groupadd -g 54321 oinstall || true
sudo groupadd -g 54322 dba || true
sudo groupadd -g 54323 oper || true
sudo groupadd -g 54324 backupdba || true
sudo groupadd -g 54325 dgdba || true
sudo groupadd -g 54326 kmdba || true
sudo groupadd -g 54327 racdba || true

sudo useradd -u 54321 -g oinstall -G dba,oper,backupdba,dgdba,kmdba,racdba oracle || true

# ---- Parametres kernel ----
sudo tee /etc/sysctl.d/98-oracle-database.conf > /dev/null <<'EOF'
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
EOF
sudo sysctl --system

# ---- Limites de ressources pour le user oracle ----
sudo tee /etc/security/limits.d/oracle-database.conf > /dev/null <<'EOF'
oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768
oracle   hard   memlock    134217728
oracle   soft   memlock    134217728
EOF

# ---- Transparent Hugepages desactive (recommandation Oracle standard) ----
sudo bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' || true
