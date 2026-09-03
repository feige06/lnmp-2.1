#!/usr/bin/env bash

DB_Info=('MySQL 5.5.62' 'MySQL 5.6.51' 'MySQL 5.7.44' 'MySQL 8.0.46' 'MySQL 8.4.10')
PHP_Info=('PHP 5.3.29' 'PHP 5.4.45' 'PHP 5.5.38' 'PHP 5.6.40' 'PHP 7.0.33' 'PHP 7.1.33' 'PHP 7.2.34' 'PHP 7.3.33' 'PHP 7.4.33' 'PHP 8.0.30' 'PHP 8.1.34' 'PHP 8.2.33' 'PHP 8.3.33' 'PHP 8.4.24' 'PHP 8.5.9')

Database_Selection()
{
    if [ -z "${DBSelect}" ]; then
        DBSelect="1"
        Echo_Yellow "You have 5 options for your MySQL install."
        for i in {1..5}; do
            [[ ${i} = 1 ]] && default=' (Default)' || default=''
            echo "${i}: Install ${DB_Info[$((i-1))]}${default}"
        done
        echo "0: DO NOT Install MySQL"
        read -p "Enter your choice (1, 2, 3, 4, 5 or 0): " DBSelect
    fi

    if [[ ! "${DBSelect}" =~ ^[0-5]$ ]]; then
        echo "No input,You will install ${DB_Info[0]}"
        DBSelect="1"
    elif [ "${DBSelect}" = "0" ]; then
        echo "Do not install MySQL!"
        return
    else
        echo "You will install ${DB_Info[$((DBSelect-1))]}"
    fi

    if [ -z "${Bin}" ]; then
        read -p "Using Generic Binaries [y/n]: " Bin
    fi
    case "${Bin}" in
    [yY][eE][sS]|[yY]) Bin="y" ;;
    [nN][oO]|[nN]) Bin="n" ;;
    *)
        if [[ "${DBSelect}" = "1" || "${CheckMirror}" = "n" ]]; then
            Bin="n"
        else
            Bin="y"
        fi
        ;;
    esac
    [[ "${Bin}" = "y" ]] && echo "Using Generic Binaries." || echo "Install from Source."

    if [ "${Bin}" != "y" ] && [[ "${DBSelect}" =~ ^[45]$ ]] && [ $(awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo) -le 1024 ]; then
        echo "Memory less than 1GB, can't install MySQL 8.*!"
        exit 1
    fi

    MySQL_Bin="/usr/local/mysql/bin/mysql"
    MySQL_Config="/usr/local/mysql/bin/mysql_config"
    MySQL_Dir="/usr/local/mysql"

    if [ -z "${DB_Root_Password}" ]; then
        echo "==========================="
        DB_Root_Password="root"
        Echo_Yellow "Please setup root password of MySQL."
        read -p "Please enter: " DB_Root_Password
        if [ -z "${DB_Root_Password}" ]; then
            echo "NO input,password will be generated randomly."
            DB_Root_Password="lnmp.org#$RANDOM"
        fi
    fi
    echo "MySQL root password: ${DB_Root_Password}"

    echo "==========================="
    if [ -z "${InstallInnodb}" ]; then
        InstallInnodb="y"
        Echo_Yellow "Do you want to enable or disable the InnoDB Storage Engine?"
        read -p "Default enable,Enter your choice [Y/n]: " InstallInnodb
    fi
    case "${InstallInnodb}" in
    [nN][oO]|[nN])
        echo "You will disable the InnoDB Storage Engine!"
        InstallInnodb="n"
        ;;
    *)
        echo "You will enable the InnoDB Storage Engine"
        InstallInnodb="y"
        ;;
    esac
}

PHP_Selection()
{
#which PHP Version do you want to install?
    if [ -z ${PHPSelect} ]; then
        echo "==========================="

        PHPSelect="3"
        Echo_Yellow "You have 15 options for your PHP install."
        for i in {1..15}; do
            [[ ${i} = 3 ]] && default=' (Default)' || default=''
            echo "${i}: Install ${PHP_Info[$((i-1))]}${default}"
        done
        read -p "Enter your choice (1-15): " PHPSelect
    fi

    case "${PHPSelect}" in
    [1-9]|1[0-5])
        echo "You will install ${PHP_Info[$((PHPSelect-1))]}"
        ;;
    *)
        echo "No input,You will install ${PHP_Info[2]}"
        PHPSelect="3"
    esac
}

MemoryAllocator_Selection()
{
#which Memory Allocator do you want to install?
    if [ -z ${SelectMalloc} ]; then
        echo "==========================="

        SelectMalloc="1"
        Echo_Yellow "You have 3 options for your Memory Allocator install."
        echo "1: Don't install Memory Allocator. (Default)"
        echo "2: Install Jemalloc"
        echo "3: Install TCMalloc"
        read -p "Enter your choice (1, 2 or 3): " SelectMalloc
    fi

    case "${SelectMalloc}" in
    1)
        echo "You will install not install Memory Allocator."
        ;;
    2)
        echo "You will install JeMalloc"
        ;;
    3)
        echo "You will Install TCMalloc"
        ;;
    *)
        echo "No input,You will not install Memory Allocator."
        SelectMalloc="1"
    esac

    if [ "${SelectMalloc}" =  "1" ]; then
        MySQLMAOpt=''
        NginxMAOpt=''
    elif [ "${SelectMalloc}" =  "2" ]; then
        MySQLMAOpt='[mysqld_safe]
malloc-lib=/usr/lib/libjemalloc.so'
        NginxMAOpt="--with-ld-opt='-ljemalloc'"
    elif [ "${SelectMalloc}" =  "3" ]; then
        MySQLMAOpt='[mysqld_safe]
malloc-lib=/usr/lib/libtcmalloc.so'
        NginxMAOpt='--with-google_perftools_module'
    fi
}

Dispaly_Selection()
{
    Database_Selection
    PHP_Selection
    MemoryAllocator_Selection
}

Kill_PM()
{
    if ps aux | grep -E "yum|dnf" | grep -qv "grep"; then
        kill -9 $(ps -ef|grep -E "yum|dnf"|grep -v grep|awk '{print $2}')
        if [ -s /var/run/yum.pid ]; then
            rm -f /var/run/yum.pid
        fi
    elif ps aux | grep -E "apt-get|dpkg|apt" | grep -qv "grep"; then
        kill -9 $(ps -ef|grep -E "apt-get|apt|dpkg"|grep -v grep|awk '{print $2}')
        if [[ -s /var/lib/dpkg/lock-frontend || -s /var/lib/dpkg/lock ]]; then
            rm -f /var/lib/dpkg/lock-frontend
            rm -f /var/lib/dpkg/lock
            dpkg --configure -a
        fi
    fi
}

Press_Install()
{
    if [ -z ${LNMP_Auto} ]; then
        echo ""
        Echo_Green "Press any key to install...or Press Ctrl+c to cancel"
        OLDCONFIG=`stty -g`
        stty -icanon -echo min 1 time 0
        dd count=1 2>/dev/null
        stty ${OLDCONFIG}
    fi
    . include/version.sh
    Kill_PM
}

Press_Start()
{
    echo ""
    Echo_Green "Press any key to start...or Press Ctrl+c to cancel"
    OLDCONFIG=`stty -g`
    stty -icanon -echo min 1 time 0
    dd count=1 2>/dev/null
    stty ${OLDCONFIG}
}

Install_LSB()
{
    echo "[+] Installing lsb..."
    if [ "$PM" = "yum" ]; then
        yum -y install redhat-lsb
    elif [ "$PM" = "apt" ]; then
        apt-get update
        apt-get --no-install-recommends install -y lsb-release
    fi
}

Get_Dist_Version()
{
    if command -v lsb_release >/dev/null 2>&1; then
        DISTRO_Version=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO_Version="$DISTRIB_RELEASE"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_Version="$VERSION_ID"
    fi
    if [[ "${DISTRO}" = "" || "${DISTRO_Version}" = "" ]]; then
        if command -v python2 >/dev/null 2>&1; then
            DISTRO_Version=$(python2 -c 'import platform; print platform.linux_distribution()[1]')
        elif command -v python3 >/dev/null 2>&1; then
            DISTRO_Version=$(python3 -c 'import platform; print(platform.linux_distribution()[1])')
        else
            Install_LSB
            DISTRO_Version=`lsb_release -rs`
        fi
    fi
    printf -v "${DISTRO}_Version" '%s' "${DISTRO_Version}"
}

Get_Dist_Name()
{
    if grep -Eqi "Alibaba" /etc/issue || grep -Eq "Alibaba Cloud Linux" /etc/*-release; then
        DISTRO='Alibaba'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun Linux" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
        DISTRO='Amazon'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Oracle Linux" /etc/issue || grep -Eq "Oracle Linux" /etc/*-release; then
        DISTRO='Oracle'
        PM='yum'
    elif grep -Eqi "rockylinux" /etc/issue || grep -Eq "Rocky Linux" /etc/*-release; then
        DISTRO='Rocky'
        PM='yum'
    elif grep -Eqi "almalinux" /etc/issue || grep -Eq "AlmaLinux" /etc/*-release; then
        DISTRO='Alma'
        PM='yum'
    elif grep -Eqi "openEuler" /etc/issue || grep -Eq "openEuler" /etc/*-release; then
        DISTRO='openEuler'
        PM='yum'
    elif grep -Eqi "Anolis OS" /etc/issue || grep -Eq "Anolis OS" /etc/*-release; then
        DISTRO='Anolis'
        PM='yum'
    elif grep -Eqi "Kylin Linux Advanced Server" /etc/issue || grep -Eq "Kylin Linux Advanced Server" /etc/*-release; then
        DISTRO='Kylin'
        PM='yum'
    elif grep -Eqi "OpenCloudOS" /etc/issue || grep -Eq "OpenCloudOS" /etc/*-release; then
        DISTRO='OpenCloudOS'
        PM='yum'
    elif grep -Eqi "Huawei Cloud EulerOS" /etc/issue || grep -Eq "Huawei Cloud EulerOS" /etc/*-release; then
        DISTRO='HCE'
        PM='yum'
    elif grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
        if grep -Eq "CentOS Stream" /etc/*-release; then
            isCentosStream='y'
        fi
    elif grep -Eqi "Red Hat Enterprise Linux" /etc/issue || grep -Eq "Red Hat Enterprise Linux" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    elif grep -Eqi "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
        DISTRO='Deepin'
        PM='apt'
    elif grep -Eqi "Mint" /etc/issue || grep -Eq "Mint" /etc/*-release; then
        DISTRO='Mint'
        PM='apt'
    elif grep -Eqi "Kali" /etc/issue || grep -Eq "Kali" /etc/*-release; then
        DISTRO='Kali'
        PM='apt'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "UnionTech OS|UOS" /etc/issue || grep -Eq "UnionTech OS|UOS" /etc/*-release; then
        DISTRO='UOS'
        if command -v apt >/dev/null 2>&1; then
            PM='apt'
        elif command -v yum >/dev/null 2>&1; then
            PM='yum'
        fi
    elif grep -Eqi "Kylin Linux Desktop" /etc/issue || grep -Eq "Kylin Linux Desktop" /etc/*-release; then
        DISTRO='Kylin'
        PM='apt'
    else
        DISTRO='unknow'
    fi
    Get_OS_Bit
}

Get_RHEL_Version()
{
    Get_Dist_Name
    if [ "${DISTRO}" = "RHEL" ]; then
        if grep -Eqi "release 5." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 5"
            RHEL_Ver='5'
        elif grep -Eqi "release 6." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 6"
            RHEL_Ver='6'
        elif grep -Eqi "release 7." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 7"
            RHEL_Ver='7'
        elif grep -Eqi "release 8." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 8"
            RHEL_Ver='8'
        elif grep -Eqi "release 9." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 9"
            RHEL_Ver='9'
        fi
        RHEL_Version="$(cat /etc/redhat-release | sed 's/.*release\ //' | sed 's/\ .*//')"
    fi
}

Get_OS_Bit()
{
    if [ "$(uname -m)" != "x86_64" ]; then
        Echo_Red "Unsupported architecture: $(uname -m). Only x86_64 is supported."
        exit 1
    fi
    ARCH='x86_64'
}

Download_Files()
{
    local URL=$1
    local FileName=$2
    if [ -s "${FileName}" ]; then
        echo "${FileName} [found]"
    else
        echo "Notice: ${FileName} not found!!!download now..."
        wget -c --progress=dot -e dotbytes=20M --prefer-family=IPv4 --no-check-certificate ${URL}
    fi
}

Tar_Cd()
{
    local FileName=$1
    local DirName=$2
    local extension=${FileName##*.}
    cd ${cur_dir}/src
    [[ -d "${DirName}" ]] && rm -rf ${DirName}
    echo "Uncompress ${FileName}..."
    if [ "$extension" == "gz" ] || [ "$extension" == "tgz" ]; then
        tar zxf "${FileName}"
    elif [ "$extension" == "bz2" ]; then
        tar jxf "${FileName}"
    elif [ "$extension" == "xz" ]; then
        tar Jxf "${FileName}"
    fi
    if [ -n "${DirName}" ]; then
        echo "cd ${DirName}..."
        cd ${DirName}
    fi
}

Check_LNMPConf()
{
    if [ ! -s "${cur_dir}/lnmp.conf" ]; then
        Echo_Red "lnmp.conf was not exsit!"
        exit 1
    fi
    if [[ "${Download_Mirror}" = "" || "${MySQL_Data_Dir}" = "" || "${Default_Website_Dir}" = "" ]]; then
        Echo_Red "Can't get values from lnmp.conf!"
        exit 1
    fi
    if [[ "${MySQL_Data_Dir}" = "/" || "${Default_Website_Dir}" = "/" ]]; then
        Echo_Red "Can't set MySQL/Website Directory to / !"
        exit 1
    fi
}

Print_APP_Ver()
{
    echo "You will install ${Stack} stack."
    echo "${Nginx_Ver}"

    if [[ "${DBSelect}" =~ ^[1-5]$ ]]; then
        echo "${Mysql_Ver}"
    elif [ "${DBSelect}" = "0" ]; then
        echo "Do not install MySQL!"
    fi

    echo "${Php_Ver}"

    if [ "${SelectMalloc}" = "2" ]; then
        echo "${Jemalloc_Ver}"
    elif [ "${SelectMalloc}" = "3" ]; then
        echo "${TCMalloc_Ver}"
    fi
    echo "Enable InnoDB: ${InstallInnodb}"
    echo "Print lnmp.conf infomation..."
    echo "Download Mirror: ${Download_Mirror}"
    echo "Nginx Additional Modules: ${Nginx_Modules_Options}"
    echo "PHP Additional Modules: ${PHP_Modules_Options}"
    if [ "${Enable_PHP_Fileinfo}" = "y" ]; then
        echo "enable PHP fileinfo."
    fi
    if [ "${Enable_Nginx_Lua}" = "y" ]; then
        echo "enable Nginx Lua."
    fi
    if [[ "${DBSelect}" =~ ^[1-5]$ ]]; then
        echo "Database Directory: ${MySQL_Data_Dir}"
    elif [ "${DBSelect}" = "0" ]; then
        echo "Do not install MySQL!"
    fi
    echo "Default Website Directory: ${Default_Website_Dir}"
}

Print_Sys_Info()
{
    echo "LNMP Version: ${LNMP_Ver}"
    eval echo "${DISTRO} \${${DISTRO}_Version}"
    cat /etc/issue
    cat /etc/*-release
    uname -a
    MemTotal=$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo)
    echo "Memory is: ${MemTotal} MB "
    df -h
    Check_Openssl
    Check_WSL
    Check_Docker
    if [ "${CheckMirror}" != "n" ]; then
        Get_Country
        echo "Server Location: ${country}"
    fi
}

StartUp()
{
    init_name=$1
    echo "Add ${init_name} service at system startup..."
    [[ "${isWSL}" = "" ]] && Check_WSL
    [[ "${isDocker}" = "" ]] && Check_Docker
    if [ "${isWSL}" = "n" ] && [ "${isDocker}" = "n" ] && command -v systemctl >/dev/null 2>&1 && [[ -s /etc/systemd/system/${init_name}.service || -s /lib/systemd/system/${init_name}.service || -s /usr/lib/systemd/system/${init_name}.service ]]; then
        systemctl daemon-reload
        systemctl enable ${init_name}.service
    else
        if [ "$PM" = "yum" ]; then
            chkconfig --add ${init_name}
            chkconfig ${init_name} on
        elif [ "$PM" = "apt" ]; then
            update-rc.d -f ${init_name} defaults
        fi
    fi
}

Remove_StartUp()
{
    init_name=$1
    echo "Removing ${init_name} service at system startup..."
    [[ "${isWSL}" = "" ]] && Check_WSL
    [[ "${isDocker}" = "" ]] && Check_Docker
    if [ "${isWSL}" = "n" ] && [ "${isDocker}" = "n" ] && command -v systemctl >/dev/null 2>&1 && [[ -s /etc/systemd/system/${init_name}.service || -s /lib/systemd/system/${init_name}.service || -s /usr/lib/systemd/system/${init_name}.service ]]; then
        systemctl disable ${init_name}.service
    else
        if [ "$PM" = "yum" ]; then
            chkconfig ${init_name} off
            chkconfig --del ${init_name}
        elif [ "$PM" = "apt" ]; then
            update-rc.d -f ${init_name} remove
        fi
    fi
}

Get_Country()
{
    if command -v curl >/dev/null 2>&1; then
        country=`curl -sSk --connect-timeout 30 -m 60 http://ip.vpszt.com/country`
        if [ $? -ne 0 ]; then
            country=`curl -sSk --connect-timeout 30 -m 60 https://ip.vpser.net/country`
        fi
    else
        country=`wget --timeout=5 --no-check-certificate -q -O - http://ip.vpszt.com/country`
    fi
}

Check_Mirror()
{
    if ! command -v curl >/dev/null 2>&1; then
        if [ "$PM" = "yum" ]; then
            yum install -y curl
        elif [ "$PM" = "apt" ]; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y curl
        fi
    fi
    if [ "${Download_Mirror}" = "https://soft.vpser.net" ]; then
        echo "Try http://soft.vpser.net ..."
        mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft.vpser.net`
        if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
            echo "http://soft.vpser.net http code: ${mirror_code}"
            ping -c 3 soft.vpser.net
        else
            ping -c 3 soft.vpser.net
            if [ "${country}" = "CN" ]; then
                echo "Try http://soft1.vpser.net ..."
                mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft1.vpser.net`
                if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
                    echo "Change to mirror http://soft1.vpser.net"
                    Download_Mirror='http://soft1.vpser.net'
                else
                    echo "Try http://soft2.vpser.net ..."
                    mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft2.vpser.net`
                    if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
                        echo "Change to mirror http://soft2.vpser.net"
                        Download_Mirror='http://soft2.vpser.net'
                    else
                        echo "Can not connect to download mirror,Please modify lnmp.conf manually."
                        echo "More info,please visit https://lnmp.org/faq/download-url.html"
                        exit 1
                    fi
                fi
            else
                echo "Try http://soft2.vpser.net ..."
                mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft2.vpser.net`
                if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
                    echo "Change to mirror http://soft2.vpser.net"
                    Download_Mirror='http://soft2.vpser.net'
                else
                    echo "Try http://soft1.vpser.net ..."
                    mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft1.vpser.net`
                    if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
                        echo "Change to mirror http://soft1.vpser.net"
                        Download_Mirror='http://soft1.vpser.net'
                    else
                        echo "Can not connect to download mirror,Please modify lnmp.conf manually."
                        echo "More info,please visit https://lnmp.org/faq/download-url.html"
                        exit 1
                    fi
                fi
            fi
        fi
    fi
}

Check_CMPT()
{
    if [[ "${DBSelect}" =~ ^[45]$ && "${Bin}" != "y" ]]; then
        if echo "${Ubuntu_Version}" | grep -Eqi "^1[0-7]\." || echo "${Debian_Version}" | grep -Eqi "^[4-8]" || echo "${Raspbian_Version}" | grep -Eqi "^[4-8]" || echo "${CentOS_Version}" | grep -Eqi "^[4-7]"  || echo "${RHEL_Version}" | grep -Eqi "^[4-7]" || echo "${Fedora_Version}" | grep -Eqi "^2[0-3]"; then
            Echo_Red "MySQL 8.* please use latest linux distributions!"
            exit 1
        fi
    fi
    if [[ "${PHPSelect}" =~ ^(9|1[0-5])$ ]]; then
        if echo "${Ubuntu_Version}" | grep -Eqi "^1[0-7]\." || echo "${Debian_Version}" | grep -Eqi "^[4-8]" || echo "${Raspbian_Version}" | grep -Eqi "^[4-8]" || echo "${CentOS_Version}" | grep -Eqi "^[4-6]"  || echo "${RHEL_Version}" | grep -Eqi "^[4-6]" || echo "${Fedora_Version}" | grep -Eqi "^2[0-3]"; then
            Echo_Red "PHP 7.4 and PHP 8.* please use latest linux distributions!"
            exit 1
        fi
    fi
}

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

Get_PHP_Ext_Dir()
{
    Cur_PHP_Version="`/usr/local/php/bin/php-config --version`"
    zend_ext_dir="`/usr/local/php/bin/php-config --extension-dir`/"
}

Check_Stack()
{
    if [[ -s /usr/local/php/sbin/php-fpm && -s /usr/local/php/etc/php-fpm.conf && -s /etc/init.d/php-fpm && -s /usr/local/nginx/sbin/nginx ]]; then
        Get_Stack="lnmp"
    else
        Get_Stack="unknow"
    fi
}

Check_DB()
{
    if [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        MySQL_Bin="/usr/local/mysql/bin/mysql"
        MySQL_Config="/usr/local/mysql/bin/mysql_config"
        MySQL_Dir="/usr/local/mysql"
        Is_MySQL="y"
        DB_Name="mysql"
    else
        Is_MySQL="None"
        DB_Name="None"
    fi
}

Do_Query()
{
    echo "$1" >/tmp/.mysql.tmp
    Check_DB
    ${MySQL_Bin} --defaults-file=~/.my.cnf </tmp/.mysql.tmp
    return $?
}

Make_TempMycnf()
{
    cat >~/.my.cnf<<EOF
[client]
user=root
password='$1'
EOF
    chmod 600 ~/.my.cnf
}

Verify_DB_Password()
{
    Check_DB
    status=1
    while [ $status -eq 1 ]; do
        read -s -p "Enter current root password of Database (Password will not shown): " DB_Root_Password
        Make_TempMycnf "${DB_Root_Password}"
        Do_Query ""
        status=$?
    done
    echo "OK, MySQL root password correct."
}

TempMycnf_Clean()
{
    if [ -s ~/.my.cnf ]; then
        rm -f ~/.my.cnf
    fi
    if [ -s /tmp/.mysql.tmp ]; then
        rm -f /tmp/.mysql.tmp
    fi
}

StartOrStop()
{
    local action=$1
    local service=$2
    [[ "${isWSL}" = "" ]] && Check_WSL
    [[ "${isDocker}" = "" ]] && Check_Docker
    if [ "${isWSL}" = "n" ] && [ "${isDocker}" = "n" ] && command -v systemctl >/dev/null 2>&1 && [[ -s /etc/systemd/system/${service}.service ]]; then
        systemctl ${action} ${service}.service
    else
        /etc/init.d/${service} ${action}
    fi
}

Check_WSL() {
    if [[ "$(< /proc/sys/kernel/osrelease)" == *[Mm]icrosoft* ]]; then
        echo "running on WSL"
        isWSL="y"
    else
        isWSL="n"
    fi
}

Check_Docker() {
    if [ -f /.dockerenv ]; then
        echo "running on Docker"
        isDocker="y"
    elif [ -f /proc/1/cgroup ] && grep -q docker /proc/1/cgroup; then
        echo "running on Docker"
        isDocker="y"
    elif [ -f /proc/self/cgroup ] && grep -q docker /proc/self/cgroup; then
        echo "running on Docker"
        isDocker="y"
    else
        isDocker="n"
    fi
}

Check_Openssl()
{
    if ! command -v openssl >/dev/null 2>&1; then
        Echo_Blue "[+] Installing openssl..."
        if [ "${PM}" = "yum" ]; then
            yum install -y openssl
        elif [ "${PM}" = "apt" ]; then
            apt-get update -y
            [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
            apt-get install -y openssl
        fi
    fi
    openssl version
    if openssl version | grep -Eqi "OpenSSL 3.*"; then
        isOpenSSL3='y'
    fi
}
