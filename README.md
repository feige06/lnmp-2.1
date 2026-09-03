# lnmp-sh

## 是什么?

LNMP一键安装包是一个用Linux Shell编写的可以为CentOS/RHEL/Fedora/Debian/Ubuntu/Deepin/Alibaba/Amazon/Mint/Oracle/Rocky/Alma/Kali/UOS/银河麒麟/openEuler/Anolis OS/OpenCloudOS/Huawei Cloud EulerOS Linux VPS或独立主机安装LNMP（Nginx/MySQL/PHP）生产环境的Shell程序。

## 有什么功能？

支持自定义Nginx、PHP编译参数及网站和数据库目录、支持生成Let's Ecrypt/ZeroSSL/BuyPass免费SSL证书、支持无人值守、LNMP模式支持多PHP版本、支持单独安装Nginx/MySQL/Pureftpd服务器，同时提供一些实用的辅助工具如：虚拟主机管理、FTP用户管理、Nginx、MySQL、PHP的升级、常见PHP模块exif、fileinfo、ldap、bz2、sodium、imap和swoole的一键安装、常用缓存组件Redis/Xcache等的安装、重置MySQL root密码、502自动重启、日志切割、SSH防护DenyHosts/Fail2Ban、备份等许多实用脚本。

## 安装

安装前确认已经安装wget命令，如提示wget: command not found ，使用 yum install wget  或  apt-get install wget  命令安装。
为防止掉线等情况，建议使用screen，可以先执行：screen -S lnmp 命令后，再执行LNMP安装命令：

```shell
wget https://soft.lnmp.com/lnmp/lnmp2.2.tar.gz -cO lnmp2.2.tar.gz
tar zxf lnmp2.2.tar.gz
cd lnmp2.2
./install.sh lnmp
```

## 自定义参数

lnmp.conf配置文件，可以修改lnmp.conf自定义下载服务器地址、网站/数据库目录及添加nginx模块和php编译参数；不论安装升级都会调用该文件里的设置(如果修改了默认的参数建议备份此文件)；
详细参数说明可以 https://lnmp.org/faq/lnmp-software-list.html#lnmp.conf 查看；

## FTP服务器

执行： ./pureftpd.sh  安装，可使用  lnmp ftp {add|list|del}  进行管理。

## 升级脚本：

执行： `./upgrade.sh`  按提示进行选择
也可以直接带参数：`./upgrade.sh {nginx|mysql|php|mphp}`

* 参数: nginx   可升级至任意Nginx版本。
* 参数: mysql   可升级至任意MySQL版本，MySQL升级风险较大，虽然会自动备份数据，依然建议自行再备份一下。
* 参数: php     可升级至大部分PHP版本。
* 参数: mphp    多PHP版本升级工具，只支持7.2.x-7.2.x类似小版本升级，大版本直接新装即可；

## 扩展插件

执行: `./addons.sh {install|uninstall} {eaccelerator|xcache|memcached|opcache|redis|apcu|imagemagick|ioncube|exif|fileinfo|ldap|bz2|sodium|imap|swoole}`
以下为扩展插件安装使用说明

### 缓存加速：

* 参数: xcache 安装时需选择版本和设置密码，http://yourIP/xcache/ 进行管理，用户名 admin，密码为安装xcache时设置的。
* 参数: redis  安装redis
* 参数: memcached 可选择php-memcache或php-memcached扩展。
* 参数: opcache 可访问 http://yourIP/ocp.php 进行管理。
* 参数: eaccelerator 安装。
* 参数: apcu 安装apcu php扩展，支持php7，可访问 http://yourIP/apc.php 进行管理。 
  **请勿安装多个缓存类扩展模块，多个可能导致网站出现问题 ！**
  PHP组件/模块：
* 参数：exif   图片exif信息读取模块。
* 参数：fileinfo   文件MIME类型编码读取模块，安装要求至少有1GB以上内存，否则可能会安装失败。
* 参数：ldap    LDAP扩展。
* 参数：bz2     bz2压缩扩展模块。
* 参数：imap    imap模块。
* 参数：swoole  PHP协程框架模块，第三方模块不支持通过lnmp.conf开启安装。

### 图像处理：

imageMagick安装卸载执行： `./addons.sh {install|uninstall} imageMagick`

imageMagick路径：/usr/local/imagemagick/bin/ 。

### 解密：

IonCube安装/卸载执行： ./addons.sh {install|uninstall} ionCube 。
Sodium加密库扩展模块安装/卸载执行：./addons.sh {install|uninstall} sodium  ，一般微信支付之类的需要使用，PHP 7.2以下版本不支持通过lnmp.conf开启安装。

### 其他常用脚本：

* 可选1，多PHP版本安装执行： ./install.sh mphp  可以安装多个PHP版本 ，只支持LNMP模式，lnmp vhost add时进行选择或使用时需要将nginx虚拟主机配置文件里的include enable-php.conf替换为 include enable-php8.4.conf 即可前面的8.4换成你刚才安装的PHP的大版本号5.*、7.*或8.*之类的。
* 可选2，数据库安装执行： ./install.sh db  可以直接单独安装MySQL数据库。
* 可选3，Nginx安装执行： ./install.sh nginx 可以直接单独安装Nginx。
  以下工具在lnmp安装包tools目录下，可拷贝到其他目录下运行
* 可选4，执行： ./reset_mysql_root_password.sh  可重置MySQL的root密码。
* 可选5，执行： ./check502.sh   可检测php-fpm是否挂掉,502报错时重启，配合crontab使用。
* 可选6，执行： ./cut_nginx_logs.sh  日志切割脚本。
* 可选7，执行： ./remove_disable_function.sh  运行此脚本可删掉禁用函数。

## 卸载

卸载LNMP可执行：`./uninstall.sh`，按提示确认即可卸载。

## 状态管理

* LNMP状态管理： lnmp {start|stop|reload|restart|kill|status} 
* Nginx状态管理： lnmp nginx或/etc/init.d/nginx {start|stop|reload|restart} 
* MySQL状态管理： lnmp mysql或/etc/init.d/mysql {start|stop|restart|reload|force-reload|status} 
* PHP-FPM状态管理： lnmp php-fpm或/etc/init.d/php-fpm {start|stop|quit|restart|reload|logrotate} 
* PureFTPd状态管理： lnmp pureftpd或/etc/init.d/pureftpd {start|stop|restart|kill|status} 

## 虚拟主机管理

* 添加： lnmp vhost add 
* 删除： lnmp vhost del 
* 列出： lnmp vhost list 
* 数据库管理： lnmp database {add|list|edit|del} 
* FTP用户管理： lnmp ftp {add|list|edit|del|show} 
* SSL添加： lnmp ssl add
* 通配符/泛域名SSL添加：lnmp dnsssl {ali|cf|dp|he|gd|aws|namecheap|namesilo}` 需依赖域名dns api

## 相关图形界面

* phpinfo：http://yourIP/phpinfo.php
* PHP探针：http://yourIP/p.php
* Xcache管理界面：http://yourIP/xcache/
* Zend Opcache管理界面：http://yourIP/ocp.php
* apcu管理界面：http://yourIP/apc.php

## LNMP相关目录文件

### 目录位置

* Nginx：/usr/local/nginx/
* MySQL：/usr/local/mysql/
* PHP：/usr/local/php/
* 多PHP目录：/usr/local/php5.6/ 版本号随安装版本不同而不同
* PHP扩展插件配置文件目录：/usr/local/php/conf.d/
* 默认虚拟主机网站目录：/home/wwwroot/default/
* Nginx日志目录：/home/wwwlogs/

### 配置文件

* Nginx主配置文件：/usr/local/nginx/conf/nginx.conf
* MySQL配置文件：/etc/my.cnf
* PHP配置文件：/usr/local/php/etc/php.ini
* PHP-FPM配置文件：/usr/local/php/etc/php-fpm.conf
* PureFtpd配置文件：/usr/local/pureftpd/etc/pure-ftpd.conf
