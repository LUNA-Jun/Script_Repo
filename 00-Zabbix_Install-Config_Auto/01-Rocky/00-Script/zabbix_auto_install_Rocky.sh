#!/bin/bash

# 설정을 엄격하게 (에러 발생시 중단, 정의되지 않은 변수 사용시 에러, 파이프 실패시 에러)
set -euo pipefail

# 스크립트 경로 기준 설정
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
LOG_FILE="${SCRIPT_DIR}/zabbix_install.log" # 로그 파일을 스크립트 위치에 저장

log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

# root 권한 체크
if [ "$EUID" -ne 0 ]; then
    log "이 스크립트는 root 권한(sudo)으로 실행해야 합니다."
    exit 1
fi

log "=== $(date '+%F %T') zabbix 설치 시작 ==="

# OS 정보 로드
if [ ! -f /etc/os-release ]; then
    log "[ERR] /etc/os-release 파일을 찾을 수 없습니다."
    exit 1
fi

. /etc/os-release

# Rocky Linux 체크
if [[ "$ID" != "rocky" ]]; then
    log "[ERR] Rocky Linux가 아닙니다. (감지된 OS: $ID). 중지합니다."
    exit 1
fi

# 메이저 버전 추출 (예: 8.9 -> 8)
OS_MAJOR_VERSION="${VERSION_ID%%.*}"

log "[INFO] Rocky Linux $VERSION_ID (Major: $OS_MAJOR_VERSION) 감지됨."

# 버전 지원 여부 체크
case "$OS_MAJOR_VERSION" in
    8|9)
        log "[INFO] 지원하는 Rocky 버전입니다."
        ;;
    *)
        log "[ERR] 지원하지 않는 Rocky 버전: ${VERSION_ID}"
        log "[HINT] 지원하는 버전 패키지를 찾아 패키지 폴더에 넣어주세요."
        exit 1
        ;;
esac

# 패키지 디렉터리 설정 (메이저 버전 사용)
PKG_ROOT_NAME="01-Packages"
PKG_DIR="${PROJECT_ROOT}/${PKG_ROOT_NAME}/${OS_MAJOR_VERSION}"

log "[INFO] 스크립트 디렉터리: ${SCRIPT_DIR}"
log "[INFO] 프로젝트 루트: ${PROJECT_ROOT}"
log "[INFO] 선택된 패키지 폴더: ${PKG_DIR}"

if [ ! -d "$PKG_DIR" ]; then
    log "[ERR] ${PKG_DIR} 폴더가 없습니다. 중지합니다."
    exit 1
fi

# 파일 검색
REPO_FILE=$(find "${PKG_DIR}" -maxdepth 1 -name "zabbix-release-*.rpm" -print -quit)
AGENT_FILE=$(find "${PKG_DIR}" -maxdepth 1 -name "zabbix-agent-*.rpm" -print -quit)

# 파일 존재 여부 확인
if [ -z "$REPO_FILE" ]; then
    log "[ERR] zabbix-release 파일을 찾을 수 없습니다."
    log "[DEBUG] 폴더 내용:"
    ls -la "${PKG_DIR}" >> "$LOG_FILE" 2>&1
    exit 1
fi

if [ -z "$AGENT_FILE" ]; then
    log "[ERR] zabbix-agent 파일을 찾을 수 없습니다."
    log "[DEBUG] 폴더 내용:"
    ls -la "${PKG_DIR}" >> "$LOG_FILE" 2>&1
    exit 1
fi

log "[INFO] 발견된 REPO 파일: ${REPO_FILE}"
log "[INFO] 발견된 AGENT 파일: ${AGENT_FILE}"

# 1) Zabbix Repository 설치 (dnf 사용 권장)
log "[INFO] zabbix-release 설치 중..."
if rpm -Uvh --replacepkgs "${REPO_FILE}" >>"$LOG_FILE" 2>&1; then
    log "[OK] zabbix-release 설치 완료"
else
    log "[ERR] zabbix-release 설치 실패"
    exit 1
fi

# 2) Zabbix Agent 설치
log "[INFO] zabbix-agent 설치 중..."
if rpm -Uvh --replacepkgs "${AGENT_FILE}" >>"$LOG_FILE" 2>&1; then
    log "[OK] zabbix-agent 설치 완료"
else
    log "[ERR] zabbix-agent 설치 실패"
    exit 1
fi

# 3) zabbix 계정 확인
ACCOUNT="zabbix"
log "[INFO] zabbix 계정 확인 중..."

if id "$ACCOUNT" >/dev/null 2>&1; then
    log "[OK] 계정 '$ACCOUNT'이 존재합니다."
else
    log "[ERR] 계정 '$ACCOUNT'이 존재하지 않습니다. 설치에 문제가 있을 수 있습니다."
fi

log "==== $(date '+%F %T') 설치 종료 ==="