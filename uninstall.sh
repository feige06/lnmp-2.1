#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

cur_dir=$(pwd)

LNMP_Ver='2.0'

. lnmp.conf
. include/main.sh

shopt -s extglob

Check_DB
Get_Dist_Name

clear
echo "+------------------------------------------------------------------------+"
echo "|          LNMP V${LNMP_Ver} for ${DISTRO} Linux Server, Written by Licess          |"
echo "+------------------------------------------------------------------------+"
echo "|        A tool to auto-compile & install Nginx+MySQL+PHP on Linux       |"
echo "+------------------------------------------------------------------------+"
echo "|           For more information please visit https://lnmp.org           |"
echo "+------------------------------------------------------------------------+"

Sleep_Sec()
{
    seconds=$1
    while [ "${seconds}" -ge "0" ];do
      echo -ne "\r     \r"
      echo -n ${seconds}
      seconds=$(($seconds - 1))
      sleep 1
    done
    echo -ne "\r"
}

Uninstall_LNMP()
{
    echo "Stoping LNMP..."
    lnmp kill
    lnmp stop

    Remove_StartUp nginx
    Remove_StartUp php-fpm
    if [ ${DB_Name} != "None" ]; then
        Remove_StartUp ${DB_Name}
        echo "Backup ${DB_Name} databases directory to /root/databases_backup_$(date +"%Y%m%d%H%M%S")"
        mv ${MySQL_Data_Dir} /root/databases_backup_$(date +"%Y%m%d%H%M%S")
    fi
    chattr -i ${Default_Website_Dir}/.user.ini
    echo "Deleting LNMP files..."
    rm -rf /usr/local/nginx
    rm -rf /usr/local/php
    rm -rf /usr/local/zend

    if [ ${DB_Name} != "None" ]; then
        rm -rf /usr/local/${DB_Name}
        rm -f /etc/my.cnf
        rm -f /etc/init.d/${DB_Name}
    fi

    for mphp in /usr/local/php[5,7].[0-9]; do
        mphp_ver=`echo $mphp|sed 's#/usr/local/php##'`
        if [ -s /etc/init.d/php-fpm${mphp_ver} ]; then
            /etc/init.d/php-fpm${mphp_ver} stop
            Remove_StartUp php-fpm${mphp_ver}
            rm -f /etc/init.d/php-fpm${mphp_ver}
        fi
        if [ -d ${mphp} ]; then
            rm -rf ${mphp}
        fi
    done

    if [ -s /usr/local/acme.sh/acme.sh ]; then
        /usr/local/acme.sh/acme.sh --uninstall
        rm -rf /usr/local/acme.sh
        if crontab -l|grep -v "/usr/local/acme.sh/upgrade.sh"; then
            crontab -l|grep -v "/usr/local/acme.sh/upgrade.sh" | crontab -
        fi
    fi

    rm -f /etc/init.d/nginx
    rm -f /etc/init.d/php-fpm
    rm -f /bin/lnmp
    echo "LNMP Uninstall completed."
}

Check_Stack
echo "Current Stack: ${Get_Stack}"
read -p "Uninstall LNMP? [y/N]: " action

case "${action}" in
[yY]|[yY][eE][sS])
    echo "You will uninstall LNMP"
    Echo_Red "Please backup your configure files and mysql data!!!!!!"
    Echo_Red "The following directory or files will be remove!"
    cat << EOF
/usr/local/nginx
${MySQL_Dir}
/usr/local/php
/etc/init.d/nginx
/etc/init.d/${DB_Name}
/etc/init.d/php-fpm
/usr/local/zend
/etc/my.cnf
/bin/lnmp
EOF
    Sleep_Sec 3
    Press_Start
    Uninstall_LNMP
    ;;
*)
    echo "Canceled."
    ;;
esac
