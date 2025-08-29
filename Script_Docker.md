# Despliegue Automatizado de Servicios Docker – Script Bash

Este script automatiza la instalación y configuración de múltiples servicios en contenedores Docker sobre un servidor Ubuntu remoto. Su objetivo es facilitar el despliegue personalizado de aplicaciones como Portainer, Pi-hole, Nextcloud, GitLab, entre otros.

---

## 🔧 Requisitos Previos (en el servidor Ubuntu)

Antes de ejecutar el script desde la máquina local, asegúrate de que el servidor Ubuntu remoto esté correctamente configurado.

### 1. Comprobar que el servidor tiene IP y está conectado a la red

```bash
ip a
ping -c 4 8.8.8.8
```

Si no tienes conectividad, edita la configuración de red:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Ejemplo de configuración mínima:

```yaml
network:
  ethernets:
    enp0s3:
      dhcp4: true
  version: 2
```

Aplica los cambios:

```bash
sudo netplan apply
```

### 2. Habilitar acceso SSH

Instala y habilita el servidor SSH:

```bash
sudo apt update && sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh
```

Verifica el estado del servicio:

```bash
sudo systemctl status ssh
```

### 3. Permitir acceso SSH como root (si se desea)

Edita el archivo de configuración de SSH:

```bash
sudo nano /etc/ssh/sshd_config
```

Busca la línea:

```
#PermitRootLogin prohibit-password
```

Y cámbiala por:

```
PermitRootLogin yes
```

Guarda el archivo y reinicia el servicio:

```bash
sudo systemctl restart ssh
```

### 4. Cambiar la contraseña del usuario root

```bash
sudo passwd root
```

---

## 💻 Configuración en la máquina local (cliente)

### 1. Generar claves SSH

```bash
ssh-keygen -t rsa -b 4096
```

Sigue las instrucciones y deja los valores por defecto.

### 2. Copiar la clave pública al servidor remoto

```bash
ssh-copy-id root@IP_DEL_SERVIDOR
```

Esto permite conectarse sin introducir contraseña cada vez.

---

## 🚀 Uso del Script

1. Añade el script a tu máquina local.
2. Otorga permisos de ejecución:

```bash
chmod +x script.sh
```----

3. Ejecuta el script:

```bash
./script.sh
```

4. Introduce los datos requeridos:
   - Usuario remoto
   - IP del servidor
   - Contraseña (si no usas clave SSH)
   - Servicios a instalar

---

## 🐳 Servicios Soportados

- Portainer
- Pi-hole
- Nextcloud
- MariaDB
- phpMyAdmin
- Rocket.Chat
- GitLab
- Uptime Kuma
- Nginx
- Watchtower

---

## 📁 Estructura del Proyecto

```bash
.
├── script.sh              # Script principal
├── servicios.txt          # Lista editable de servicios
├── Logs.txt               # Registro local de operaciones
└── README.md              # Este documento
```

---

## 🔐 Seguridad

- Se recomienda usar autenticación por clave SSH en lugar de contraseña.
- El script realiza cambios automáticos que pueden afectar la seguridad (como reinicio de UFW y uso de root).

---

## 📌 Notas Finales

Este script está diseñado para fines educativos y de pruebas. Puede ser adaptado y extendido según necesidades específicas.

Autor: David Díaz Moreno  
Versión: 1.0  
Fecha: 06/06/2025
