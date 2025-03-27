#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/bultodepapas/frigate/refs/heads/main/build.func)
# Copyright (c) 2021-2025 tteck
# Authors: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://frigate.video/

APP="Frigate"
var_tags="nvr"
var_cpu="12"   # Número de núcleos de CPU que quieres asignar
var_ram="8192" # 8 GB de RAM para garantizar un buen rendimiento
var_disk="20"
var_os="debian"
var_version="11"
var_unprivileged="0"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/frigate.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_error "To update Frigate, create a new container and transfer your configuration."
  exit
}

# Función para establecer los límites de recursos del contenedor
function set_limits() {
    local container_conf="/etc/pve/lxc/${CTID}.conf"
    
    if [[ -f "$container_conf" ]]; then
        echo "Configuring resource limits for Frigate container..."
        
        # Establecer límites de archivos abiertos (nofile) en un número muy alto
        echo "lxc.prlimit.nofile: 1048576" >> "$container_conf"
        
        # Establecer límites de procesos (nproc) para manejar muchos procesos simultáneos
        echo "lxc.prlimit.nproc: 65535" >> "$container_conf"
        
        # Establecer límite de memoria (en este caso, 8GB)
        echo "lxc.cgroup2.memory.limit_in_bytes: 8G" >> "$container_conf"
        
        # Asegurarse de que tenga suficiente acceso a la CPU
        echo "lxc.cgroup2.cpu.shares: 1024" >> "$container_conf"   # Mayor prioridad de CPU
        echo "lxc.cgroup2.cpuset.cpus: 0-11" >> "$container_conf"  # Usar los primeros 12 núcleos disponibles
        
        # Ajustar otros límites importantes
        echo "lxc.prlimit.stack: 8192" >> "$container_conf"  # Asegurar que el tamaño de pila sea grande
        echo "lxc.prlimit.memlock: unlimited" >> "$container_conf"  # Asegurar que no haya limitación en la memoria bloqueada
        
        msg_ok "Resource limits set successfully!"
    else
        msg_error "Configuration file for the container not found!"
        exit 1
    fi
}

start
build_container
set_limits  # Aplicar los límites de recursos después de la construcción del contenedor
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
