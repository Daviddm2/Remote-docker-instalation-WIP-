#!/bin/bash

# Variables
USER="david"
IP="192.168.20.1"
SUDO_PASS="1234"

# Conexión SSH y comandos remotos
ssh -t ${USER}@${IP} << EOF
 systemctl stop docker
 systemctl disable docker
 apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
apt-get purge -y docker docker-engine docker.io containerd runc
apt-get autoremove -y --purge
rm -rf /var/lib/docker
rm -rf /etc/docker
groupdel docker
rm /etc/apparmor.d/docker || true
 echo "Docker completamente eliminado."
EOF

exit 0
