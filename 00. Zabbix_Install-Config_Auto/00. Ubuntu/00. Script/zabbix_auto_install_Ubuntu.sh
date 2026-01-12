#!/bin/bash

set -euo pipefail

LOG_FILE="./zabbix_install.log"

# root Check
if [ "$EUID" -ne 0 ]; then
    echo "이 스크립트는 root권한(sudo)으로 실행해야합니다."
    exit 1
fi

# Ubuntu/Debian Check
if ! grep -qiE "ubuntu|debian" /etc/os-release; then
    echo "Ubuntu/Debian 계열이 아닙니다. 중지합니다."
    exit 1
fi

echo "=== $(date '+%F %T') zabbix 설치 시작 === " | tee -a "$LOG_FILE"

# Check File
REPO_PATTERN="zabbix-release_latest_*"
AGENT_PATTERN="zabbix-agent_*"

if ! ls ${REPO_PATTERN} >/dev/null 2>&1; then
    echo "[ERR] ${REPO_PATTERN} 파일이 없습니다. 현재 디렉터리를 확인하세요." | tee -a "$LOG_FILE"
    exit 1
fi

if ! ls ${AGENT_PATTERN} >/dev/null 2>&1; then
    echo "[ERR] ${AGENT_PATTERN} 파일이 없습니다. 현재 디렉터리를 확인하세요." | tee -a "$LOG_FILE"
    exit 1
fi


# 1) Zabbix Repository Install
echo "[INFO] zabbix-release 설치 중..." | tee -a "$LOG_FILE"

if dpkg -i ${REPO_PATTERN} >>"$LOG_FILE" 2>&1; then
    echo "[OK] zabbix-release 설치 완료" | tee -a "$LOG_FILE"
else
    echo "[ERR] zabbix-release 설치 실패" | tee -a "$LOG_FILE"
fi


# 2) Zabbix Agent Install
echo "[INFO] zabbix-agent 설치 중..." | tee -a "$LOG_FILE"

if dpkg -i --force-depends ${AGENT_PATTERN} >>"$LOG_FILE" 2>&1; then
    echo "[OK] zabbix-agent 설치 완료" | tee -a "$LOG_FILE"
else
    echo "[ERR] zabbix-agent 설치 실패" | tee -a "$LOG_FILE"
fi


# 3) Check the "zabbix" ID
ACCOUNT="zabbix"

echo "[INFO] zabbix 계정 확인 중..." | tee -a "$LOG_FILE"

if cat /etc/passwd | grep "$ACCOUNT" >/dev/null 2>&1; then
    echo "[OK] 계정 '$ACCOUNT'이 존재합니다." | tee -a "$LOG_FILE"
else
    echo "[ERR] 계정 '$ACCOUNT'이 존재하지 않습니다. 설치에 문제가 있을 수 있습니다." | tee -a "$LOG_FILE"
fi


# 4) libmodbus Settings
LIBFILE="./libmodbus.so.5.1.0"
LIBDIR="/usr/local/lib"
DEST_LIB="$LIBDIR/libmodbus.so.5.1.0"
TARGET_LIB="$LIBDIR/libmodbus.so.5"

echo "[INFO] libmodbus 라이브러리 설정 작업 실행..." | tee -a "$LOG_FILE"

# If there is a file in the LIBFILE path, copy it to /usr/local/lib
if [ -f "$LIBFILE" ]; then
    echo "[INFO] $LIBFILE -> $LIBDIR 로 복사" | tee -a "$LOG_FILE"
    cp -f "$LIBFILE" "$DEST_LIB"
fi

# LIBFILE check
if [ -f "$LIBFILE" ]; then
    cd "$LIBDIR"

    # Create Symbolic Link
    if [ ! -L "$TARGET_LIB" ]; then
        ln -s "DEST_LIB" "TARGET_LIB"
        echo "[OK] libmodbus.so.5 링크 생성 완료" | tee -a "$LOG_FILE"
    else
        echo "[INFO] libmodbus.so.5 링크가 이미 존재합니다." | tee -a "$LOG_FILE"
    fi
    
    # Auth Configuration
    chmod 755 libmodbus.so.*
    echo "[OK] libmodbus.so.* 권한 설정 완료" | tee -a "$LOG_FILE"

    # Refresh cache
    ldconfig
    echo "[OK] ldconfig 실행 완료" | tee -a "$LOG_FILE"
else
    echo "[WARN] $DEST_LIB 파일이 존재하지 않아 libmodbus 설정을 건너 뜁니다." | tee -a "$LOG_FILE"
fi

echo "==== $(date '+%F %T') 설치 종료 ===" | tee -a "$LOG_FILE"