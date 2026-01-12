#!/bin/bash
set -euo pipefail

LOG_FILE="./zabbix_config_setup.log"
CONF_FILE="/etc/zabbix/zabbix_agentd.conf"
SCRIPT_PATH="./zabbix_auto_install_Rocky"

usage() {
    echo "사용법:"
    echo "  sudo $0 <ZABBIX_SERVER_IP>"
    echo
    echo "예시:"
    echo "  sduo $0 192.168.0.10"
}

# root Check
if [ "$EUID" -ne  0 ]; then
    echo "이 스크립트는 root권한(sudo)으로 실행해야합니다."
    exit 1
fi

# Input IP (Zabbix Server IP)
if [ "${1:-}" = "" ]; then
    usage
    exit 1
fi

SERVER_IP="$1"

# Current Server IP Auto-Detections
HOST_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')"

if [ -z "${HOST_IP}" ]; then
    echo "[ERR] 현재 서버 IP를 자동으로 가져오지 못했습니다."
    exit 1
fi

# Zabbix Config
echo "=== $(date '+%F %T') zabbix 설정 시작 ===" | tee -a "$LOG_FILE"
echo "[INFO] Server/ServerActive = ${SERVER_IP}" | tee -a "$LOG_FILE"
echo "[INFO] Hostname(현재 서버 IP) = ${HOST_IP}" | tee -a "$LOG_FILE"

# Zabbix Install Check
if ! dpkg -l | awk '{print $2}' | grep -q '^zabbix-agent$'; then
    echo "[ERR] zabbix-agent가 설치되어 있지 않습니다." | tee -a "$LOG_FILE"
    echo "먼저 아래 설치 스크립트를 실행하세요." | tee -a "$LOG_FILE"
    echo "> ${SCRIPT_PATH}" | tee -a "$LOG_FILE"
    echo "설정 작업을 중단 합니다." | tee -a "$LOG_FILE"
    exit 1
fi

echo "[OK] zabbix-agent 설치 확인됨" | tee -a "$LOG_FILE"

# Zabbix Config file check
if [ ! -f "$CONF_FILE" ]; then
    echo "[ERR] 설정 파일이 존재하지 않습니다: $CONF_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# Make BackupFile
BACKUP_FILE="${CONF_FILE}.bak.$(date '+%Y%m%d_%H%M%S')"
cp -a "$CONF_FILE" "$BACKUP_FILE"
echo "[OK] 설정 백업 파일 생성: $BACKUP_FILE" | tee -a "$LOG_FILE"

# Edit only non-comment(#) lines
sed -i \
    -e "/^[[:space:]]*#/! s/^[[:space:]]*Server=.*/Server=${SERVER_IP}/" \
    -e "/^[[:space:]]*#/! s/^[[:space:]]*ServerActive=.*/ServerActive=${SERVER_IP}/" \
    -e "/^[[:space:]]*#/! s/^[[:space:]]*Hostname=.*/Hostname=${HOST_IP}/" \
    "$CONF_FILE"

# If there is no item, add it
if ! grep -Eq '^[[:space:]]*Server=' "$CONF_FILE"; then
    echo "Server=${SERVER_IP}" >> "$CONF_FILE"
    echo "[INFO] Server 항목이 없어 추가했습니다." | tee -a "$LOG_FILE"
fi

if ! grep -Eq '^[[:space:]]*ServerActive=' "$CONF_FILE"; then
    echo "ServerActive=${SERVER_IP}" >> "$CONF_FILE"
    echo "[INFO] ServerActive 항목이 없어 추가했습니다." | tee -a "$LOG_FILE"
fi

if ! grep -Eq '^[[:space:]]*Hostname=' "$CONF_FILE"; then
    echo "Hostname=${HOST_IP}" >> "$CONF_FILE"
    echo "[INFO] Hostname 항목이 없어 추가했습니다." | tee -a "$LOG_FILE"
fi

echo "[OK] 설정 파일 수정 완료" | tee -a "$LOG_FILE"
echo "[INFO] 적용 결과(요약)" | tee -a "$LOG_FILE"
grep -nE '^[[:space:]]*(Server|ServerActive|Hostname)=' "$CONF_FILE" | tee -a "$LOG_FILE"

# Zabbix Restart
echo "[INFO] zabbix-agent 데몬 갱신" | tee -a "$LOG_FILE"
systemctl daemon-reload |& tee -a "$LOG_FILE"

echo "[INFO] zabbix-agent 재부팅 시 자동으로 실행(enable)" | tee -a "$LOG_FILE"
systemctl enable zabbix-agent |& tee -a "$LOG_FILE"

echo "[INFO] zabbix-agent 서비스 재시작" | tee -a "$LOG_FILE"
systemctl restart zabbix-agent |& tee -a "$LOG_FILE"

echo "[INFO] zabbix-agent 서비스 상태 확인" | tee -a "$LOG_FILE"
systemctl --no-pager --full status zabbix-agent |& tee -a "$LOG_FILE" || true

echo "==== $(date '+%F %T') 설정 종료 ====" | tee -a "$LOG_FILE"