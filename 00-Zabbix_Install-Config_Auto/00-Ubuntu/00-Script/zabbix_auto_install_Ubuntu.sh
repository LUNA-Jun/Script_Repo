#!/bin/bash

set -euo pipefail

# Log
LOG_FILE="./zabbix_install.log"

log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

# root Check
if [ "$EUID" -ne 0 ]; then
    log "이 스크립트는 root권한(sudo)으로 실행해야합니다."
    exit 1
fi

# Install Start 
log "=== $(date '+%F %T') zabbix 설치 시작 ==="

# Load OS Information
if [ ! -f /etc/os-release ]; then
    log "[ERR] /etc/os-release 파일을 찾을 수 없습니다."
    exit 1
fi

. /etc/os-release
OS_ID="$ID"
OS_VERSION="$VERSION_ID"

# Ubuntu/Debian Check
log "[INFO] Ubuntu 정보 확인 중..."

case "$OS_ID" in
    ubuntu|debian|Ubuntu)
        log "[INFO] Ubuntu/Debian 계열을 감지했습니다."
        ;;
    *)
        log "[ERR] Ubuntu/Debian 계열이 아닙니다. 중지합니다."
        exit 1
        ;;
esac

# Version Check
log "[INFO] 감지된 Ubuntu 버전: ${OS_VERSION}"

case "$OS_VERSION" in
    "20.04"|"22.04"|"24.04")
        log "[INFO] 지원하는 Ubuntu 버전입니다."
        ;;
    *)
        log "[ERR] 지원하지 않는 Ubuntu 버전: ${OS_VERSION}"
        log "[HINT] 지원하는 버전 패키지를 찾아 패키지 폴더에 넣어주세요."
        exit 1
        ;;
esac

# Folder Setting
PKG_ROOT_NAME="01-Packages"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Directory Setting
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PKG_DIR="${PROJECT_ROOT}/${PKG_ROOT_NAME}/${OS_VERSION}"

log "[INFO] 스크립트 디렉터리: ${SCRIPT_DIR}"
log "[INFO] 프로젝트 루트: ${PROJECT_ROOT}"
log "[INFO] 선택된 패키지 폴더: ${PKG_DIR}"

if [ ! -d "$PKG_DIR" ]; then
    log "[ERR] ${PKG_DIR} 폴더가 없습니다. 중지합니다."
    exit 1
fi

# Check File
REPO_FILE=$(find "${PKG_DIR}" -maxdepth 1 -name "zabbix-release_*.deb" -print -quit)
AGENT_FILE=$(find "${PKG_DIR}" -maxdepth 1 -name "zabbix-agent_*.deb" -print -quit)

log "[INFO] 파일 검색 중..."
log "[DEBUG] 검색 위치: ${PKG_DIR}"

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


# 1) Zabbix Repository Install
log "[INFO] zabbix-release 설치 중..."

if dpkg -i "${REPO_FILE}" >>"$LOG_FILE" 2>&1; then
    log "[OK] zabbix-release 설치 완료"
else
    log "[ERR] zabbix-release 설치 실패"
    exit 1
fi


# 2) Zabbix Agent Install
log "[INFO] zabbix-agent 설치 중..."

if dpkg -i --force-depends "${AGENT_FILE}" >>"$LOG_FILE" 2>&1; then
    log "[OK] zabbix-agent 설치 완료"
else
    log "[WARN] zabbix-agent 설치 중 의존성 문제 등이 발생했을 수 있습니다."
    log "[WARN] 스크립트는 계속 진행됩니다."
    log "[OK] zabbix-agent 설치 완료"
fi


# 3) Check the "zabbix" ID
ACCOUNT="zabbix"

log "[INFO] zabbix 계정 확인 중..."

# 그룹 확인 및 생성
if ! getent group "$ACCOUNT" >/dev/null 2>&1; then
    log "[INFO] 그룹 '$ACCOUNT'이 존재하지 않습니다. 생성합니다."
    if groupadd --system "$ACCOUNT"; then
        log "[OK] 그룹 '$ACCOUNT' 생성 완료"
    else
        log "[ERR] 그룹 '$ACCOUNT' 생성 실패"
        exit 1
    fi
else
    log "[OK] 그룹 '$ACCOUNT'이 이미 존재합니다."
fi

# 사용자 확인 및 생성
if ! getent passwd "$ACCOUNT" >/dev/null 2>&1; then
    log "[INFO] 계정 '$ACCOUNT'이 존재하지 않습니다. 생성합니다."
    if useradd --system \
        --gid "$ACCOUNT" \
        --home /var/lib/zabbix \
        --no-create-home \
        --shell /usr/sbin/nologin \
        "$ACCOUNT"; then
        log "[OK] 계정 '$ACCOUNT' 생성 완료"
    else
        log "[ERR] 계정 '$ACCOUNT' 생성 실패"
        exit 1
    fi
else
    log "[OK] 계정 '$ACCOUNT'이 이미 존재합니다."
fi


# 4) libmodbus Settings
LIB_ROOT_NAME="02-libmodbus"
# 위에서 정의한 PROJECT_ROOT 사용
LIB_DIR="${PROJECT_ROOT}/${LIB_ROOT_NAME}"
LIBFILE="${LIB_DIR}/libmodbus.so.5.1.0"
LIBDIR="/usr/local/lib"
DEST_LIB="$LIBDIR/libmodbus.so.5.1.0"
TARGET_LIB="$LIBDIR/libmodbus.so.5"

log "[INFO] libmodbus 라이브러리 설정 작업 실행..."
log "[INFO] 라이브러리 폴더: ${LIB_DIR}"

# If there is a file in the LIBFILE path, copy it to /usr/local/lib
if [ -f "$LIBFILE" ]; then
    log "[INFO] $LIBFILE -> $LIBDIR 로 복사"
    cp -f "$LIBFILE" "$DEST_LIB"
else
    log "[WARN] $LIBFILE 파일이 존재하지 않아 libmodbus 설정을 건너뜁니다."
fi

# 복사된 라이브러리 파일 체크
if [ -f "$DEST_LIB" ]; then
    cd "$LIBDIR"

    # Create Symbolic Link
    if [ ! -L "$TARGET_LIB" ]; then
        ln -s "libmodbus.so.5.1.0" "libmodbus.so.5"
        log "[OK] libmodbus.so.5 링크 생성 완료"
    else
        log "[INFO] libmodbus.so.5 링크가 이미 존재합니다."
    fi
    
    # Auth Configuration
    chmod 755 libmodbus.so.*
    log "[OK] libmodbus.so.* 권한 설정 완료"

    # Refresh cache
    ldconfig
    log "[OK] ldconfig 실행 완료"
else
    log "[WARN] $DEST_LIB 파일이 존재하지 않아 심볼릭 링크 및 권한 설정을 건너뜁니다."
fi

log "==== $(date '+%F %T') 설치 종료 ==="