---
title: Vagrant虚拟机Ubuntu16.04安装MariaDB
layout: post
tags: [Vagrant, Ubuntu, MariaDB]
categories: [Vagrant]
date: 2017-04-10T00:00:00+08:00
---

由于宿主机安装了MySQL，为了避免安装MariaDB造成MySQL无法使用，所以在Vagrant中安装Mariadb

更换[网易apt-get源](http://mirrors.163.com/.help/ubuntu.html) `/etc/apt/sources.list`

读取源软件列表 `sudo apt update`

更新软件版本 `sudo apt upgrade`

安装MariaDB  `sudo apt install mariadb-server`

安全性设置更新root密码 `sudo mysql_secure_installation`

服务器开始远程登陆：my.cnf中`bind_address`改为0.0.0.0

为登陆用户开启远程登陆权限：

```sql
>>GRANT ALL PRIVILEGES ON *.* TO myuser@'%' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;
>>FLUSH PRIVILEGES;
```

重启MariaDB `service mysql restart`

Vagrantfile中config.vm.network
```
config.vm.network "forwarded_port", guest: 3306, host: 8306
```
重启Vagrant虚拟机 `vagrant reload`

最后在宿主机连接MariaDB的命令：
```
mysql -u root -h 127.0.0.1 -P 8306 -p
```

期间遇到无法reset MariaDB的root用户的密码，通过[这里](https://superuser.com/questions/949496/cant-reset-mysql-mariadb-root-password)解决了，大致就是在安全模式下登陆，清空root的plugin，然后将密码写入表中。
