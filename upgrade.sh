#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1
fi

cur_dir=$(pwd)
action=$1
shopt -s extglob
Upgrade_Date=$(date +"%Y%m%d%H%M%S")

. lnmp.conf
. include/version.sh
. include/main.sh
. include/init.sh
. include/php.sh
. include/nginx.sh
. include/mysql.sh
. include/upgrade_nginx.sh
. include/upgrade_php.sh
. include/upgrade_mysql.sh
. include/upgrade_mphp.sh

Get_Dist_Name
Get_Dist_Version
MemTotal=$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo)

Display_Upgrade_Menu()
{
    echo "1: Upgrade Nginx"
    echo "2: Upgrade MySQL"
    echo "3: Upgrade PHP"
    echo "4: Upgrade Multiple PHP"
    echo "exit: Exit current script"
    echo "###################################################"
    read -p "Enter your choice (1, 2, 3, 4 or exit): " action
}

clear
echo "+-----------------------------------------------------------------------+"
echo "|            Upgrade script for LNMP V2.1, Written by Licess            |"
echo "+-----------------------------------------------------------------------+"
echo "|               A tool to upgrade Nginx, MySQL and PHP                  |"
echo "+-----------------------------------------------------------------------+"
echo "|           For more information please visit https://lnmp.org          |"
echo "+-----------------------------------------------------------------------+"

if [ "${action}" == "" ]; then
    Display_Upgrade_Menu
fi

    case "${action}" in
    1|[nN][gG][iI][nN][xX])
        Upgrade_Nginx 2>&1 | tee /root/upgrade_nginx${Upgrade_Date}.log
        ;;
    2|[mM][yY][sS][qQ][lL])
        Upgrade_MySQL 2>&1 | tee /root/upgrade_mysq${Upgrade_Date}.log
        ;;
    3|[pP][hP][pP])
        Stack="lnmp"
        Upgrade_PHP 2>&1 | tee /root/upgrade_lnmp_php${Upgrade_Date}.log
        ;;
    4|[mM][pP][hH][pP])
        Upgrade_Multiplephp 2>&1 | tee /root/upgrade_mphp${Upgrade_Date}.log
        ;;
    [eE][xX][iI][tT])
        exit 1
        ;;
    *)
        echo "Usage: ./upgrade.sh {nginx|mysql|php|mphp}"
        exit 1
    ;;
    esac
