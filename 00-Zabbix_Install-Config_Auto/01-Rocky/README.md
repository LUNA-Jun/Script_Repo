# Zabbix Auto Install_Rocky Linux

# 설명

## 개요

본 스크립트는 Rocky Linux 서버에 Zabbix Agent를 자동으로 설치하고 설정하는 스크립트입니다.

## 스크립트 버전

<table style="border-collapse: collapse; width: auto;">
   <tr>
      <th>버전</th>
      <th>설명</th>
   </tr>
   <tr>
      <td>1.0.0</td>
      <td>초기 버전</td>
   </tr>
   <tr>
      <td>1.0.1</td>
      <td>1. Rocky Linux 패키지 버전에 따라 설치 되도록 수정
         <br/> 2. 사용자 친화적으로 수정
         <br/> 3. 스크립트 고도화
      </td>
   </tr>
</table>

## 폴더 구조

| 폴더명      | 설명                    |
| ----------- | ----------------------- |
| 00-Script   | 스크립트 파일           |
| 01-Packages | Rocky Linux 패키지 파일 |

# 사용방법

> 폐쇄망 and 방화벽으로 인해 인터넷이 불가능한 환경에서만 사용하고 테스트함

1. `00-Rocky` 폴더를 Zabbix 설치해야 될 서버에 복사
   <br/>

2. `01-Rocky` - `00-Script` 폴더 내에서 `sudo ./zabbix_auto_install_Rocky.sh` 명령어 실행
   **스크립트 진행 시 메시지 출력 확인 필수**

   <br/>

3. Zabbix 설정 스크립트 실행 `sudo ./zabbix_auto_config.sh [Zabbix 서버 IP]` 명령어 실행
