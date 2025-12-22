Zabbix Auto Install_Ubuntu
========

# 사용방법

1. `Ubuntu(Packgage) 폴더`에 있는 agent, release 파일을 서버에 설치된 버전에 따라 `Script 폴더`에 이동
<br/>

2. `Temp_lib 폴더`에 있는 `libmodbus`파일을 `Script 폴더`에 이동
> `libmodubs`버전에 업데이트가 있을 경우 스크립트 수정 필요
> ```
>    libmodbus Settings
>    LIBFILE="./libmodbus.so.5.1.0"            --> 수정 
>    DEST_LIB="$LIBDIR/libmodbus.so.5.1.0"     --> 수정
>    TARGET_LIB="$LIBDIR/libmodbus.so.5"       --> 수정
> ```
<br/>

3. 스크립트가 있는 폴더 내에서 `sudo ./zabbix_auto_install_Ubuntu.sh` 명령어 실행
__스크립트 진행 시 메시지 출력 확인 필수__
> 스크립트 완료 후 agent 설치에서 의존성으로 인해 에러가 뜨지만 무시해도 됨 

<br/>

4. Zabbix 설정 스크립트 실행 `sudo ./zabbix_auto_config.sh [Zabbix 서버 IP]` 명령어 실행