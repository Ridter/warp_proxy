#!/bin/bash
NC="\033[0m"
RED='\033[31m'
GREEN='\033[32m'
Yellow="\033[33m"
NC='\033[0m'


log() {
    local LEVEL="$1"
    local MSG="$2"
    case "${LEVEL}" in
    INFO)
        local LEVEL="[${GREEN}${LEVEL}${NC}]"
        local MSG="${LEVEL} ${MSG}"
        ;;
    WARN)
        local LEVEL="[${Yellow}${LEVEL}${NC}]"
        local MSG="${LEVEL} ${MSG}"
        ;;
    ERROR)
        local LEVEL="[${RED}${LEVEL}${NC}]"
        local MSG="${LEVEL} ${MSG}"
        ;;
    *) ;;
    esac
    echo -e "${MSG}"
}

function reconnect_warp() {
    while true; do

    # 检查连接状态
    status=$(warp-cli --accept-tos status)

    # 如果已经连接，断开现有连接
    if [[ $(echo "$status" | grep -c "Status update: Connected") -eq 1 ]]; then
        warp-cli --accept-tos disconnect
    fi

    # 尝试连接并检查连接状态
    warp-cli --accept-tos connect
    status=$(warp-cli --accept-tos status)

    # 等待连接成功
    while [[ $(echo "$status" | grep -c "Status update: Connecting") -eq 1 ]]; do
        log WARN "connecting..."
        sleep 2
        status=$(warp-cli --accept-tos status)
    done
    # 如果连接成功，等待 wait_time 分钟后再次尝试
    if [[ $(echo "$status" | grep -c "Status update: Connected") -eq 1 ]]; then
        current_ip=$(curl -x socks5://127.0.0.1:1080 -ksm8 -A Mozilla https://api.ip.sb/geoip | grep -oP '(?<="ip":")[^"]+' | sed 's/\\//g')
        log INFO "connection succeeded ! IP: $current_ip"
        sleep $(($wait_time * 60))
    else
        # 如果连接失败，等待10秒后重试
        log ERROR "connection failed, retrying in 10 seconds..."
        sleep 10
    fi
    done
}

function init_server(){
    process_status=$(pgrep -c 'socat')
    # 如果未找到 socat 进程，启动服务
    if [[ $process_status -eq 0 ]]; then
        screen -dmS warp warp-svc 
        screen -dmS socat socat TCP-LISTEN:1080,fork,reuseaddr TCP:127.0.0.1:40000 
        
        # 等待服务启动
        log INFO "Starting services..."
        while true; do
            warp_status=$(pgrep -c 'warp-svc')
            socat_status=$(pgrep -c 'socat')
            
            if [[ $warp_status -gt 0 && $socat_status -gt 0 ]]; then
                log INFO "Services started successfully"
                break
            else
                log WARN "Waiting for services to start..."
                sleep 2
            fi
        done
    else
        echo "Server is already running"
    fi
    
    warp-cli --accept-tos registration new
    warp-cli --accept-tos mode proxy
}

# 检查是否有输入参数，如果没有，则使用默认的10分钟
if [ -z "$1" ]; then
  wait_time=60
else
  wait_time=$1
fi

init_server
# 等待服务启动
sleep 3
# 自动连接
reconnect_warp