#!/bin/bash
#===============================================================================
# Название: Kudesnik-IT - Docker Daemon Configuration Script (KIT-DDCS)
#
# Описание: Этот скрипт автоматизирует настройку конфигурационного файла Docker (`daemon.json`):
#   - Создает файл `/etc/docker/daemon.json` с указанными параметрами.
#   - Делает резервную копию существующего файла, если он существует.
#   - Перезапускает службу Docker и проверяет статус.
#  _  __              _                        _   _              ___   _____ 
# | |/ /  _   _    __| |   ___   ___   _ __   (_) | | __         |_ _| |_   _|
# | ' /  | | | |  / _` |  / _ \ / __| | '_ \  | | | |/ /  _____   | |    | |  
# | . \  | |_| | | (_| | |  __/ \__ \ | | | | | | |   <  |_____|  | |    | |  
# |_|\_\  \__,_|  \__,_|  \___| |___/ |_| |_| |_| |_|\_\         |___|   |_|  
#                                                                             
# Автор: Kudesnik-IT <kudesnik.it@gmail.com>
# GitHub: https://github.com/Kudesnik-IT/docker-daemon-setup
# Версия: 1.0
# Дата создания: 2025-02-12
# Последнее обновление: 2025-02-12
#===============================================================================
# Лицензия: MIT License
# Copyright (c) 2025 Kudesnik-IT
#
# Разрешается свободное использование, копирование, модификация, объединение,
# публикация, распространение, сублицензирование и/или продажа копий ПО.
# Зависимости:
# - Bash (тестировано на версии 4.0+)
# - Docker (тестировано на версии 20.10+)
# - Coreutils (для команды cp, echo, sleep и т.д.)
# - Systemd (для управления службой Docker)
# Инструкции по использованию:
# 1. Сделайте скрипт исполняемым: chmod +x docker_daemon_config.sh
# 2. Запустите скрипт с правами root: ./docker_daemon_config.sh
# 3. Следуйте инструкциям на экране.
# История изменений:
# v1.0 (2025-02-12): Первая версия скрипта.
#===============================================================================


set -e                    # automatically terminate execution on first error
set -u                    # prevent use of undefined variables
set -o pipefail           # handle errors in pipelines


##########################
# --- DEFINE VARIABLES ---
##########################

DAEMON_JSON="/etc/docker/daemon.json"      # Путь к конфигурационному файлу Docker


###################
# --- FUNCTIONS ---
###################

# Function to output messages with indentation
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Функция для проверки статуса Docker с таймаутом
check_docker_status() {
  local max_attempts=10  # Максимальное количество попыток
  local delay=3          # Задержка между попытками (в секундах)
  
  for ((i=1; i<=max_attempts; i++)); do
    if systemctl is-active --quiet docker; then
      echo "Docker запущен"
      return 0
    elif [ $i -lt $max_attempts ]; then
      echo "Docker еще не активен. Ожидание $delay секунд..."
      sleep $delay
    else
      echo "Ошибка: Таймаут $((max_attempts * delay)) сек - Docker не запустился"
      return 1
    fi
  done
}


##############
# --- MAIN ---
##############

CONFIG='{
  "iptables": true,
  "live-restore": true,
  "bip": "192.168.2.254/27",
  "ipv6": false,
  "default-address-pools": [{
    "base": "192.168.2.0/24",
    "size": 27
  }]
}'

cat <<EOF

██╗  ██╗██╗   ██╗██████╗ ███████╗███████╗███╗   ██╗██╗██╗  ██╗     ██╗████████╗
██║ ██╔╝██║   ██║██╔══██╗██╔════╝██╔════╝████╗  ██║██║██║ ██╔╝     ██║╚══██╔══╝
█████╔╝ ██║   ██║██║  ██║█████╗  ███████╗██╔██╗ ██║██║█████╔╝█████╗██║   ██║   
██╔═██╗ ██║   ██║██║  ██║██╔══╝  ╚════██║██║╚██╗██║██║██╔═██╗╚════╝██║   ██║   
██║  ██╗╚██████╔╝██████╔╝███████╗███████║██║ ╚████║██║██║  ██╗     ██║   ██║   
╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝     ╚═╝   ╚═╝   
...................................................
   Docker Daemon Configuration Script (KIT-DDCS)
'''''''''''''''''''''''''''''''''''''''''''''''''''
This script configures docker parameters...


EOF

# Проверяем, существует ли уже файл /etc/docker/daemon.json
if [ -f "$DAEMON_JSON" ]; then
  log "Файл $DAEMON_JSON уже существует. Создаем резервную копию..."
  cp "$DAEMON_JSON" "$DAEMON_JSON.bak"
fi

# Создаем или обновляем файл daemon.json
log "$CONFIG" > "$DAEMON_JSON"

# Проверяем, успешно ли создан файл
if [ $? -eq 0 ]; then
  log "Файл $DAEMON_JSON успешно создан."
else
  log "Ошибка при создании файла $DAEMON_JSON."
  exit 1
fi

# Перезапускаем Docker
log "Перезапуск Docker..."
systemctl restart docker

# Вызываем функцию проверки статуса
if check_docker_status; then
  exit 0
else
  exit 1
fi

#---
# Автор: Kudesnik-IT <kudesnik.it@gmail.com>
# GitHub: https://github.com/Kudesnik-IT/docker-daemon-setup
#---