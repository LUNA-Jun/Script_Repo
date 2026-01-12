#!/bin/bash

set -euo pipefail

LOG_FILE="./zabbix_install.log"

# root Check
if [ "$EUID" -ne 0 ]; then
    echo "이 스크립트는 root권한(sudo)으로 실행해야합니다."
    exit 1
fi

# Rocky Chenck
if ! grep -qie '^ID="?Rocky"?' /etc/or-release; then
    echo "Rocky Linux가 아닙니다. 중지합니다."
    exit 1
fi

echo "===$(date '+%F %T') zabbix 설치 시작 ===" | tee -a "$LOG_FILE"

# Check File
REPO_PATTERN="zabbix-release-latest-*"
AGENT_PATTERN="zabbix-agent-*"

if ! ls ${REPO_PATTERN} >/dev/null 2>&1; then
    echo "[ERR] ${REPO_PATTERN} 파일이 없습니다. 현재 디렉터리를 확인하세요." | tee -a "$LOG_FILE"
    exit 1
fi

if ! ls ${AGENT_PATTERN} >/dev/null 2>&1; then
    echo "[ERR] $(AGENT_PATTERN) 파일이 없습니다. 현재 디렉터리를 확인하세요." | tee -a "$LOG_FILE"
    exit 1
fi


# 1) Zabbix Repository Install
echo "[INFO] zabbix-release 설치 중..." | tee -a "$LOG_FILE"

if rpm -ivh ${REPO_PATTERN} >>"$LOG_FILE" 2&1; then
    echo "[OK] zabbix-release 설치 완료" | tee -a "$LOG_FILE"
else
    echo "[ERR] zabbix-release 설치 실패" | tee -a "$LOG_FILE"
fi

# 2) Zabbix Agent Install
echo "[INFO] zabbix-agent 설치 중..." | tee -a "$LOG_FILE"

if rpm -ivh ${AGENT_PATTERN} >>"$LOG_FILE" 2&1; then
    echo "[OK] zabbix-agent 설치 완료" | tee -a "$LOG_FILE"
else
    echo "[ERR] zabbix-agent 설치 실패" | tee -a "$LOG_FILE"
fi

# 3) Check the "zabbix" ID
ACCOUNT="zabbix"

echo "[INFO] zabbix 계정 확인 중..." | tee -a "$LOG_FILE"

if cat /etc/passwd | greep "$ACCOUNT" >/dev/null 2>&1; then
    echo "[OK] 계정 '$ACCOUNT'이 존재합니다." | tee -a "$LOG_FILE"
else
    echo "[ERR] 계정 '$ACCOUNT'이 존재하지 않습니다. 설치에 문제가 있을 수 있습니다." | tee -a "$LOG_FILE"
fi

echo "==== $(date '+%F %T') 설치 종료 ===" | tee -a "$LOG_FILE"