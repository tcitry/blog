---
layout: post
title: Ubuntu下部署Django应用
tags: [Python, Django]
categories: [Python]
date: 2014-10-28T00:00:00+08:00
---


做了一个Django小应用，主要内容是一个论坛，经过好几天的研究，也可以在服务器端运行了，以下所有代码中的操作都需要在命令行运行。

## 安装MySQL

```bash
apt-get update
apt-get install mysql-server mysql-client
```

根据提示设置MySQL root用户密码

## MySQL设置中文utf8格式

一般在`/etc/mysql`下

[client]下添加`default-character-set=utf8`

[mysqld]下添加`character-set-server=utf8`

[mysql]下添加`default-character-set=utf8`

重启MySQL

```bash
service mysql restart
```

进入MySQL查看编码

```bash
show variables like 'char%';
```

![](/img/2014-10-28-djangoapp.png)

## 为MySQL建立远程连接

由于修改数据库时不可能频繁的登服务器在命令行下修改，远程用workbench连接MySQL服务器是更方便的选择，先登入MySQL，授权一个可以远程连接这个数据库的用户名和密码

```mysql
>>GRANT ALL PRIVILEGES ON *.* TO myuser@'%' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;
>>FLUSH PRIVILEGES;
```

有的MySQL没有开放远程连接的端口，只允许本地连接，你需要查看my.conf之类的文件，我的在`/etc/mysql/my.conf`把

```bash
bind-address:127.0.0.1
```

那行注释掉即可

## 安装pip
[下载地址](https://pypi.python.org/pypi/pip#downloads)

```bash
apt-get install python-pip
```

## 安装django1.7
[django官网](https://www.djangoproject.com/)

```bash
pip install Django==1.7
```

python进入python2.7解释器

```bash
>>import django
>>
```

不出错说明安装成功

## 安装mysql-python

安装mysql-python注意需要配置`mysql_config`我的在(/usr/bin目录下，其他的类似也在bin目录下，视不同系统不同版本而定)如果 `/usr/bin`目录下没有`mysql_config`，需要安装mysql开发包

```bash
apt-get install python-setuptools
apt-get install libmysqld-dev
apt-get install libmysqlclient-dev
apt-get install python-dev
```

[下载链接](https://pypi.python.org/pypi/MySQL-python/)

```bash
wget 'url'
```

解压zip文件，首先安装unzip

```bash
apt-get install unzip
unzip mysql-python.zip
cd mysql-python
vi site.cfg
```

把`mysql_config`路径那行取消注释，路径为`/usr/bin/mysql_config`

```bash
cd ..
python setup.py build
python setup.py install
```

进去python解释器

```bash
>>import MySQLdb
>>
```

不报错说明安装成功

MySQLdb不支持python3，可以试试pymysql，同时在Python3的项目中，需要在`__init__.py`中添加

```bash
import pymysql
pymysql.install_as_MySQLdb()
```

这是由于Django调用MySQL的接口问题，在setting.py文件中具体为`'ENGINE': 'django.db.backends.mysql',`，仔细查看这句代码就会发现Django默认调用的是MySQLdb，虽然它只支持Python2.0。

## 配置nginx
最重要的就是nginx的配置

我的配置目录在`/etc/nginx/nginx.conf`和`/etc/nginx/sites-enable/*`后者可以在前者文件中设置，先查看配置文件`/etc/nginx/sites-enable/django`

![](/img/2014-10-28-nginxsetting.png)

根据自己的应用修改配置文件中static路径，server_name，root等。修改完毕注意要`service nginx reload`

关于静态文件的地址配置还是需要多说一句，nginx中的`/static`目录对应的是`setting.py`文件中的`STATIC_ROOT`目录，两个写一样的，执行`python manage.py collectstatic`收集的文件是admin后台模块的静态样式文件，执行完后这些静态文件就被复制在你设置的`STATIC_ROOT`目录了。


## 部署代码
因为我的代码在github，先安装git

```bash
apt-get install git
git clone https://github.com/tcitry/dlpucsdn.git
```

部署以后注意修改数据库密码，邮件服务器密码，debug模式False，template_debug模式为False。

## virtualenv

```bash
pip install virtualenv
```

根据网上现有的教程简单看看virtualenv的使用很容易理解，在项目依赖的相关程序配置过程中需要始终开着virtualenv。

## 配置Gunicorn
查看这个[教程](https://www.digitalocean.com/community/tutorials/how-to-use-the-django-one-click-install-image)修改为自己的应用参数

```bash
service gunicorn restart
```

当部署一个应用时可以将配置文件放在`/etc/init.d/gunicorn.conf`文件里面。但同时部署多个文件的时候，可以使用supervisor+gunicorn+virtualenv的部署方式，这样可以在每个不同的项目目录利用virtualenv为每个应用配置不同的环境，同时可以使服务器的环境更加易于管理。

先在项目的根目录测试一下，确保gunicorn安装正确，

```bash
../bin/gunicorn myapp.wsgi:application
```

不出错就说明正确了，出错一般是提示没有那个module名，检查一下django是否安装，执行命令的文件目录是否正确。

## supervisor的使用

```bash
apt-get install supervisor
sudo vim /etc/supervisord.conf
```

编辑的内容如下，请自行修改项目和目录名。

```bash
[program:classroom]
command = sh /home/projects/classroom/classroom/gunicorn_start
user = root
redirect_stderr = true
autorestart = true
```

配置这个gunicorn_start.sh

```bash
cd /home/projects/classroom/classroom
../bin/gunicorn classroom.wsgi:application -w 4 -b :8000
```

启动supervisor

```bash
/etc/init.d/supervisord start
```

其他方式

```bash
supervisorctl start <name>
supervisorctl stop <name>
```

## 安装七牛云SDK
由于网站的静态存储要用七牛云，在运行程序前要安装否则报错没有qiniu SDK的方法。

```bash
pip install qiniu
```

七牛云安装前注意安装的版本，我被坑过一次，写程序时是6.0版本，部署时都7.0了，接口全都不一样。

## 还有
还有不推荐cloudflare等国外CDN加速，亲身体验。

还有推荐下这篇来自digitalocean的[部署实例](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-django-with-postgres-nginx-and-gunicorn)
