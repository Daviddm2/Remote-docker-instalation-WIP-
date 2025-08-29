#!/bin/bash
Logslocal=/home/david/Desktop/TFG/Logs.txt
Logsremoto=/home/david/TFG/Logs.txt
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y > $Logslocal
echo "-----------------------------------------------------------------------" >> $Logslocal
echo "Bienvenido al programa de instalacion remota de docker"

Actualizar() {
  ssh "$user@$ip" << EOF
  set -e
  Logsremoto=/home/david/TFG/Logs.txt
  apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --batch --yes -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

  echo "Anadiendo repositorio oficial docker" >> "$Logsremoto" 2>&1

  apt update >> "$Logsremoto" 2>&1
  echo "-----------------------------------------------------------------------" >> "$Logsremoto" 2>&1
  apt full-upgrade -y >> "$Logsremoto" 2>&1
  echo "-----------------------------------------------------------------------" >> "$Logsremoto" 2>&1
  apt autoremove -y >> "$Logsremoto" 2>&1
EOF
}

docker_remoto() {
  ssh "$user@$ip" << EOF
    set -e

    Logsremoto=/home/david/TFG/Logs.txt
    apt update

    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> "$Logsremoto" 2>&1
    echo "Habilitando servicios necesarios"
    systemctl enable containerd
    systemctl start containerd

    systemctl enable docker docker.socket containerd
    systemctl start docker docker.socket containerd

    echo "Docker instalado y servicios arrancados"

    usermod -aG docker $user
EOF
}
docker_reset() {
  ssh "$user@$ip" << EOF
    set -e
    service docker restart
    service docker status
EOF
}
docker_borrar() {
  ssh "$user@$ip" << EOF
    set -e
    Logsremoto=/home/david/TFG/Logs.txt

    containers=\$(docker ps -q)
    if [ -n "\$containers" ]; then
      docker stop \$containers
      docker rm \$containers
    else
      echo "No hay contenedores activos" >> "$Logsremoto" 2>&1
    fi

    systemctl stop docker docker.socket containerd
    systemctl disable docker docker.socket containerd

    rm -rf /var/lib/docker /etc/docker /var/lib/containerd

    apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker docker-engine docker.io containerd runc >> "\$Logsremoto" 2>&1
    apt-get autoremove -y --purge >> "\$Logsremoto" 2>&1

    groupdel docker || true
    rm -f /etc/apparmor.d/docker || true

    systemctl daemon-reload
    systemctl reset-failed

  echo "Docker completamente eliminado." >> "\$Logsremoto"

EOF
}
portainer(){
  Logsremoto="/home/david/TFG/Logs.txt"
  echo ""
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  cat <<'EOF' 
 _______  _______  ______    _______  _______  ___   __    _  _______  ______   
|       ||       ||    _ |  |       ||   _   ||   | |  |  | ||       ||    _ |  
|    _  ||   _   ||   | ||  |_     _||  |_|  ||   | |   |_| ||    ___||   | ||  
|   |_| ||  | |  ||   |_||_   |   |  |       ||   | |       ||   |___ |   |_||_ 
|    ___||  |_|  ||    __  |  |   |  |       ||   | |  _    ||    ___||    __  |
|   |    |       ||   |  | |  |   |  |   _   ||   | | | |   ||   |___ |   |  | |
|___|    |_______||___|  |_|  |___|  |__| |__||___| |_|  |__||_______||___|  |_|


EOF
echo "-----------------------------------------------------------------------"
echo "Instalando Portainer en el host remoto..."
ssh "$user@$ip" << EOF
  set -e
  docker pull portainer/portainer-ce:lts >> "$Logsremoto" 2>&1
  docker volume create portainer_data >> "$Logsremoto" 2>&1

  # Elimina cualquier despliegue anterior (opcional)
  docker rm -f portainer 2>/dev/null || true 

  docker run -d \
    --name portainer \
    --restart=always \
    -p 8000:8000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:lts >> "$Logsremoto" 2>&1
 ufw allow 9443/tcp
 ufw disable
 ufw enable
  
EOF
echo "-----------------------------------------------------------------------"
echo ""
echo ""
echo "puede iniciar sesion a Portainer desde http://$ip:$puerto"
sleep 5
firefox "https://$ip:9443" &>/dev/null &
echo "-----------------------------------------------------------------------"
echo "-----------------------------------------------------------------------"
sleep 5
echo ""
echo ""
}
instalar_nextcloud() {
  Logsremoto="/home/david/TFG/Logs.txt"
  echo ""
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  cat <<'EOF' 
 __    _  _______  __   __  _______  _______  ___      _______  __   __  ______  
|  |  | ||       ||  |_|  ||       ||       ||   |    |       ||  | |  ||      | 
|   |_| ||    ___||       ||_     _||       ||   |    |   _   ||  | |  ||  _    |
|       ||   |___ |       |  |   |  |       ||   |    |  | |  ||  |_|  || | |   |
|  _    ||    ___| |     |   |   |  |      _||   |___ |  |_|  ||       || |_|   |
| | |   ||   |___ |   _   |  |   |  |     |_ |       ||       ||       ||       |
|_|  |__||_______||__| |__|  |___|  |_______||_______||_______||_______||______| 


EOF
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  echo ""
  echo ""
  read -p "Puerto HTTP para nextcloud (por ej. 8080): " puerto
  ssh "$user@$ip" << EOF

  docker pull nextcloud >> "$Logsremoto" 2>&1

  docker volume create nextcloud_data >> "$Logsremoto" 2>&1

  docker run -d \
    --name nextcloud \
    -p $puerto:80 \
    -v nextcloud_data:/var/www/html \
  nextcloud << "$Logsremoto" 2>&1
   ufw allow $puerto/tcp
   ufw disable
   ufw enable
  
EOF
echo "-----------------------------------------------------------------------"
echo ""
echo ""
echo "puede iniciar sesion a Nextcloud desde http://$ip:8081"
sleep 5
firefox "http://$ip:8081"
echo "-----------------------------------------------------------------------"
echo "-----------------------------------------------------------------------"
sleep 5
echo ""
echo ""
}
instalar_Nginx() {
  Logsremoto="/home/david/TFG/Logs.txt"
  echo ""
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  cat <<'EOF' 
           __    _  _______  ___   __    _  __   __ 
          |  |  | ||       ||   | |  |  | ||  |_|  |
          |   |_| ||    ___||   | |   |_| ||       |
          |       ||   | __ |   | |       ||       |
          |  _    ||   ||  ||   | |  _    | |     | 
          | | |   ||   |_| ||   | | | |   ||   _   |
          |_|  |__||_______||___| |_|  |__||__| |__|


EOF
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  echo ""
  echo ""
  read -p "Puerto HTTP para nginx (por ej. 8080): " puerto
  ssh "$user@$ip" << EOF
  docker pull Nginx << "$Logsremoto" 2>&1

  docker volume create nginx_html >> "$Logsremoto" 2>&1
  docker volume create nginx_conf >> "$Logsremoto" 2>&1

  docker run -d \
    --name nginx \
    -p $puerto:80 \
    -v nginx_html:/usr/share/nginx/html \
    -v nginx_conf:/etc/nginx/conf.d \
    nginx >> "$Logsremoto" 2>&1
   ufw allow $puerto/tcp
   ufw disable
   ufw enable
  
EOF

echo "-----------------------------------------------------------------------"
echo ""
echo ""
echo "puede acceder a Nginx desde http://$ip:8082"
sleep 5
firefox "http://$ip:8082"
echo "-----------------------------------------------------------------------"
echo "-----------------------------------------------------------------------"
sleep 5
echo ""
echo ""
}

instalar_Pi_hole() {
  Logsremoto="/home/david/TFG/Logs.txt"
  echo ""
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  cat <<'EOF' 
       _______  ___          __   __  _______  ___      _______ 
      |       ||   |        |  | |  ||       ||   |    |       |
      |    _  ||   |  ____  |  |_|  ||   _   ||   |    |    ___|
      |   |_| ||   | |____| |       ||  | |  ||   |    |   |___ 
      |    ___||   |        |       ||  |_|  ||   |___ |    ___|
      |   |    |   |        |   _   ||       ||       ||   |___ 
      |___|    |___|        |__| |__||_______||_______||_______|

EOF
  read -p "Puerto HTTP para Pi-hole (por ej. 8080): " puerto
  read -p "Introduce la contraseña web para Pi-hole: " contrapihole
  echo

  ssh root@"$ip" <<EOF
    set -e

    docker rm -f pihole 2>/dev/null || true
    docker volume rm pihole_config pihole_dnsmasq 2>/dev/null || true >> "$Logsremoto" 2>&1

    docker volume create pihole_config >> "$Logsremoto" 2>&1
    docker volume create pihole_dnsmasq >> "$Logsremoto" 2>&1

    docker pull pihole/pihole:latest

    docker run -d --name pihole \
      -e TZ="Europe/Madrid" \
      -e WEBPASSWORD="$contrapihole" \
      -p $puerto:80 \
      -p 5353:53/tcp -p 5353:53/udp \
      -v pihole_config:/etc/pihole \
      -v pihole_dnsmasq:/etc/dnsmasq.d \
      --cap-add=NET_ADMIN \
      pihole/pihole:latest >> "$Logsremoto" 2>&1
    sleep 15


  docker exec pihole pihole setpassword "$contrapihole"
EOF
echo "-----------------------------------------------------------------------"
echo ""
echo ""
echo "puede acceder a pihole desde http://$ip:8083/admin/"
sleep 5
firefox "http://$ip:8083/admin"
echo "-----------------------------------------------------------------------"
echo "-----------------------------------------------------------------------"
sleep 5
echo ""
}

instalar_MariaDB() {
  Logsremoto="/home/david/TFG/Logs.txt"
  echo ""
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  cat <<EOF 
       __   __  _______  ______    ___   _______  ______   _______ 
      |  |_|  ||   _   ||    _ |  |   | |   _   ||      | |  _    |
      |       ||  |_|  ||   | ||  |   | |  |_|  ||  _    || |_|   |
      |       ||       ||   |_||_ |   | |       || | |   ||       |
      |       ||       ||    __  ||   | |       || |_|   ||  _   | 
      | ||_|| ||   _   ||   |  | ||   | |   _   ||       || |_|   |
      |_|   |_||__| |__||___|  |_||___| |__| |__||______| |_______|


EOF
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  echo ""
  echo ""
  read -p "Introduce la contraseña ROOT para MariaDB: " rootpass
  read -p "Introduce el nombre de la base de datos a crear: " dbname
  read -p "Introduce el nombre de usuario a crear: " usersql
  read -p "Introduce la contraseña para el nuevo usuario: " sqlpass
  ssh "$user@$ip" << EOF
  docker volume create mariadb_data >> "$Logsremoto" 2>&1
  
  docker pull mariadb  >> "$Logsremoto" 2>&1

  docker run -d \
    --name mariadb \
    -e MYSQL_ROOT_PASSWORD=$rootpass \
    -e MYSQL_DATABASE=$dbname \
    -e MYSQL_USER=$usersql \
    -e MYSQL_PASSWORD=$sqlpass \
    -v mariadb_data:/var/lib/mysql \
    mariadb >> "$Logsremoto" 2>&1
EOF
}

instalar_phpMyAdmin() {
  Logsremoto="/home/david/TFG/Logs.txt"
  echo ""
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  cat <<'EOF' 
  _______  __   __  _______  __   __  __   __  _______  ______   __   __  ___   __    _ 
  |       ||  | |  ||       ||  |_|  ||  | |  ||   _   ||      | |  |_|  ||   | |  |  | |
  |    _  ||  |_|  ||    _  ||       ||  |_|  ||  |_|  ||  _    ||       ||   | |   |_| |
  |   |_| ||       ||   |_| ||       ||       ||       || | |   ||       ||   | |       |
  |    ___||       ||    ___||       ||_     _||       || |_|   ||       ||   | |  _    |
  |   |    |   _   ||   |    | ||_|| |  |   |  |   _   ||       || ||_|| ||   | | | |   |
  |___|    |__| |__||___|    |_|   |_|  |___|  |__| |__||______| |_|   |_||___| |_|  |__|


EOF
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  echo ""
  echo ""
  read -p "Puerto HTTP para phpmyadmin (por ej. 8080): " puerto
  ssh "$user@$ip" << EOF
  docker pull phpmyadmin >> "$Logsremoto" 2>&1

  docker run -d \
    --name phpmyadmin \
    -e PMA_HOST=mariadb \
    -p $puerto:80 \
    --link mariadb \
    phpmyadmin/phpmyadmin >> "$Logsremoto" 2>&1
     ufw allow $puerto/tcp
     ufw disable
     ufw enable
EOF
echo "-----------------------------------------------------------------------"
echo ""
echo ""
echo "puede acceder a phpmyadmin desde http://$ip:8084"
sleep 5
firefox "http://$ip:8084"
echo "-----------------------------------------------------------------------"
echo "-----------------------------------------------------------------------"
sleep 5
echo ""
}

instalar_GitLab() {
  Logsremoto="/home/david/TFG/Logs.txt"
  echo ""
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  cat <<EOF 
           _______  ___   _______  ___      _______  _______ 
          |       ||   | |       ||   |    |   _   ||  _    |
          |    ___||   | |_     _||   |    |  |_|  || |_|   |
          |   | __ |   |   |   |  |   |    |       ||       |
          |   ||  ||   |   |   |  |   |___ |       ||  _   | 
          |   |_| ||   |   |   |  |       ||   _   || |_|   |
          |_______||___|   |___|  |_______||__| |__||_______|


EOF
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  echo ""
  echo ""
  read -p "IP del servidor: " ip
  read -p "Puerto HTTP para GitLab (por ej. 8080): " puerto

  ssh root@"$ip" bash -s <<EOF
set -e

docker network inspect gitlab-net >/dev/null 2>&1 || \
  docker network create gitlab-net  >> "$Logsremoto" 2>&1

docker rm -f gitlab 2>/dev/null || true >> "$Logsremoto" 2>&1

docker volume inspect gitlab_config  >> "$Logsremoto" 2>&1
docker volume inspect gitlab_logs  >> "$Logsremoto" 2>&1
docker volume inspect gitlab_data  >> "$Logsremoto" 2>&1

docker pull gitlab/gitlab-ce:latest  >> "$Logsremoto" 2>&1

docker run -d --hostname gitlab.example.com --name gitlab --network gitlab-net \
  -p $puerto:80 -p 2222:22 \
  -v gitlab_config:/etc/gitlab \
  -v gitlab_logs:/var/log/gitlab \
  -v gitlab_data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest >> "$Logsremoto" 2>&1
   ufw allow $puerto/tcp
   ufw disable
   ufw enable
  
EOF
}
instalar_Rocket.Chat() {
  Logsremoto="/home/david/TFG/Logs.txt"
  echo ""
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
    cat <<'EOF' 
  ______    _______  _______  ___   _  _______  _______  _______  __   __  _______  _______ 
  |    _ |  |       ||       ||   | | ||       ||       ||       ||  | |  ||   _   ||       |
  |   | ||  |   _   ||       ||   |_| ||    ___||_     _||       ||  |_|  ||  |_|  ||_     _|
  |   |_||_ |  | |  ||       ||      _||   |___   |   |  |       ||       ||       |  |   |  
  |    __  ||  |_|  ||      _||     |_ |    ___|  |   |  |      _||       ||       |  |   |  
  |   |  | ||       ||     |_ |    _  ||   |___   |   |  |     |_ |   _   ||   _   |  |   |  
  |___|  |_||_______||_______||___| |_||_______|  |___|  |_______||__| |__||__| |__|  |___|  


EOF
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  echo ""
  echo ""
  read -p "IP del servidor: " ip
  read -p "Puerto HTTP para Rocket.Chat (por ej. 3000): " puerto

  ssh root@"$ip" bash -s <<EOF
set -e

docker network create rocketchat-net  >> "$Logsremoto" 2>&1

docker run -d --name db --network rocketchat-net \
  -v mongodb_data:/data/db \
  mongo:6.0 \
    --replSet rs0 \
    --bind_ip_all

until docker exec db mongosh --quiet --eval "db.adminCommand('ping')"  >> "$Logsremoto" 2>&1
  sleep 2
done

docker exec db mongosh --quiet --eval "printjson(rs.initiate())" || true

docker run -d --name rocketchat --network rocketchat-net \
  -e MONGO_URL="mongodb://db:27017/rocketchat" \
  -e MONGO_OPLOG_URL="mongodb://db:27017/local" \
  -e ROOT_URL="http://$ip:$puerto" \
  -p $puerto:3000 \
  rocketchat/rocket.chat:latest >> "$Logsremoto" 2>&1
   ufw allow $puerto/tcp
   ufw disable
   ufw enable
  
EOF
echo "-----------------------------------------------------------------------"
echo ""
echo ""
echo "puede acceder a rocketchat desde http://$ip:$puerto"
sleep 5
firefox "http://$ip:$puerto"
echo "-----------------------------------------------------------------------"
echo "-----------------------------------------------------------------------"
sleep 5
echo ""
}

instalar_Uptime_Kuma() { 
  Logsremoto="/home/david/TFG/Logs.txt"
  echo ""
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  cat <<'EOF' 
 __   __  _______  _______  ___   __   __  _______          ___   _  __   __  __   __  _______ 
|  | |  ||       ||       ||   | |  |_|  ||       |        |   | | ||  | |  ||  |_|  ||   _   |
|  | |  ||    _  ||_     _||   | |       ||    ___|        |   |_| ||  | |  ||       ||  |_|  |
|  |_|  ||   |_| |  |   |  |   | |       ||   |___         |      _||  |_|  ||       ||       |
|       ||    ___|  |   |  |   | |       ||    ___|        |     |_ |       ||       ||       |
|       ||   |      |   |  |   | | ||_|| ||   |___  _____  |    _  ||       || ||_|| ||   _   |
|_______||___|      |___|  |___| |_|   |_||_______||_____| |___| |_||_______||_|   |_||__| |__|


EOF
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  echo ""
  echo ""
  read -p "Puerto HTTP para uptime-kuma (por ej. 3000): " puerto
  ssh "$user@$ip" << EOF
  docker volume create uptimekuma_data  >> "$Logsremoto" 2>&1

  docker pull louislam/uptime-kuma:latest  >> "$Logsremoto" 2>&1

  docker run -d --name uptime-kuma \
  -p $puerto:3001 \
  -v uptimekuma_data:/app/data \
  louislam/uptime-kuma:latest
   ufw allow $puerto/tcp
   ufw disable
   ufw enable
  
EOF
echo "-----------------------------------------------------------------------"
echo ""
echo ""
echo "puede acceder a Uptime_kuma desde http://$ip:8086"
sleep 5
firefox "http://$ip:8086"
echo "-----------------------------------------------------------------------"
echo "-----------------------------------------------------------------------"
sleep 5
echo ""
}


instalar_Watchtower() {
 Logsremoto="/home/david/TFG/Logs.txt"
 echo ""
 echo ""
 echo "-----------------------------------------------------------------------"
 echo "-----------------------------------------------------------------------"
 cat <<'EOF' 
 _     _  _______  _______  _______  __   __  _______  _______  _     _  _______  ______   
| | _ | ||   _   ||       ||       ||  | |  ||       ||       || | _ | ||       ||    _ |  
| || || ||  |_|  ||_     _||       ||  |_|  ||_     _||   _   || || || ||    ___||   | ||  
|       ||       |  |   |  |       ||       |  |   |  |  | |  ||       ||   |___ |   |_||_ 
|       ||       |  |   |  |      _||       |  |   |  |  |_|  ||       ||    ___||    __  |
|   _   ||   _   |  |   |  |     |_ |   _   |  |   |  |       ||   _   ||   |___ |   |  | |
|__| |__||__| |__|  |___|  |_______||__| |__|  |___|  |_______||__| |__||_______||___|  |_|



EOF
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"
  echo ""
  echo ""
  read -p "Intervalo de comprobación para Watchtower en segundos (por ej. 300): " timertower
  
  ssh "$user@$ip" << EOF
  docker pull containrrr/watchtower:latest  >> "$Logsremoto" 2>&1
  
  docker run -d --name watchtower \
   -v /var/run/docker.sock:/var/run/docker.sock \
   containrrr/watchtower:latest \
   --interval $timertower \
   --cleanup
EOF
echo "-----------------------------------------------------------------------"
echo ""
echo ""
echo "Ya tiene watchtower instalado en $ip"
echo "-----------------------------------------------------------------------"
echo "-----------------------------------------------------------------------"
sleep 5
echo ""
}


read -p "Indique el usuario del servidor en el que desea instalar el servicio " user

echo $user

read -p "Indique la Ip del servidor en el que desea instalar el servicio " ip

echo $ip

read -s -p "Indique la contrasena del servidor en el que desea instalar el servicio " contra

echo $contra
echo "actualizando servidor"

Actualizar
echo ""
echo ""
docker_borrar
echo ""
echo ""
docker_remoto
echo "Ahora va a instalarse docker"
echo ""
echo ""

#Ahora se va a instalar portainer para docker

portainer
echo " se va a mostrar una lista de contenedores listos para instalar"
echo "-----------------------------------------------------------------------"
echo "-----------------------------------------------------------------------"
mapfile -t lista < servicios.txt
bucle="si"
while [ "$bucle" == "si" ]; do
  # Mostrar menú con select
  select servicio in "${lista[@]}"; do
    if [[ -n "$servicio" ]]; then
      echo "Has seleccionado: $servicio"
      break
    else
      echo "Opción inválida. Intenta de nuevo."
    fi
  done
  case $servicio in
    "Nginx")
    instalar_Nginx
    ;;
    "Nextcloud")
    instalar_nextcloud
    ;;
    "Pi-hole")
    instalar_Pi_hole
    ;;
    "MariaDB")
    instalar_MariaDB
    ;;
    "phpMyAdmin")
    instalar_phpMyAdmin
    ;;
    "Rocket.Chat")
    instalar_Rocket.Chat
    ;;
    "Watchtower")
    instalar_Watchtower
    ;;
    "GitLab")
    instalar_GitLab
    ;;
    "Uptime Kuma")
    instalar_Uptime_Kuma
    ;;
    "Exit")
    bucle="no"
    ;;
  esac
done
