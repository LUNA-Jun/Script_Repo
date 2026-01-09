#!/bin/bash

LOG_FILE="./zabbix_install.log"

# root Check

# Rocky Check
if ! grep -qiE 

# Check File
REPO_PATTERN="zabbix-release-latest-*"
AGENT_PATTERN=""

# 2) Zabbix Agent Install
echo "[INFO] zabbix-agent 설치 중..." | tee -a "$LOG_FILE"

if rpm -ivh 
fi

# 3) Check the "zabbix" ID
ACCOUNT="zabbix"

echo "[INFO] zabbix 계정 확인 중..." | tee -a "$LOG_FILE"

if cat /etc/passwd | greep "$ACCOUNT" >/dev/null 2>&1; then
    echo "[OK] 계정 '$ACCOUNT'이 존재합니다." | tee -a "$LOG_FILE"
else
    echo "[ERR] 계정 '$ACCOUNT'이 존재하지 않습니다. 설치에 문제가 있을 수 있습니다." | tee -a "$LOG_FILE"
fi