---
title: MacOS Users Management
date: 2018-09-11
tags: macos user dscl dscacheutil sysadminctl useradd usermod userdel
---

Современные операционные системы [многопользовательские](https://en.wikipedia.org/wiki/Multi-user_software). И macOS не является исключение в этом плане. Даже если вы единственный пользователь своего MacBook или iMac и не создавали ни одного дополнительного персонажа, все равно есть еще другие предустановленные пользователи для системного обслуживания (root, daemon, nobody). Давайте попробуем разобраться, какие есть инструменты управления пользователями в яблочном саду.

Рядовой пользователь macOS обычно управляет настройками пользователей и групп через графический интерфейс системных настроек – **System Preferences –> Users & Groups**. Из названия видно, что пользователи могу принадлежать (одной или нескольким) группам, но в рамках этой заметки я бы хотел сконцентрироваться больше на пользователях, а не на группах. И конечно же мы будем эксперементировать из командной строки в рамках **macOS High Sierra 10.13.6**. 

Итак для начала давайте составим достаточно стандартный список команд управления пользователями:

1. Показать информацию о всех и конкретном
2. Создать
3. Изменить
4. Удалить

В macOS основные функции учета пользователей (в том числе и сетевых) возлагаются на **Directory Service**. Одним из интрументов работы с сервисом является `dscl` – **Directory Service Command Line Utility** – утилита общего назначения для управления директориями пользователей, котороая может работать в интерактивном режиме. Параметер `.` в командах `dscl` представленных ниже определяет локальный (не сетевой) домен пользователей. Еще есть менее известные инструменты `dscacheutil` (**Directory Service Cache Utility**) и `sysadminctl`.

#### Информация о всех существующих пользователях

##### Список всех пользователей (включая системных)

    $ dscl . -list /Users
    _amavisd
    _analyticsd
    _appleevents
    _applepay
    ...
    Guest
    nobody
    root
    tensho
    
##### Список обыкновенных пользователей

    $ dscl . -list /Users | grep -v '^_'
    daemon
    Guest
    nobody
    root
    tensho
    
##### UID и GID обыкновенных пользователей 

     $ dscl . -list /Users UniqueID | grep -v '^_'
     daemon                  1
     Guest                   201
     nobody                  -2
     root                    0
     tensho                  501
     $ dscl . -list /Users PrimaryGroupID | grep -v '^_'
     bob                     20
     daemon                  1
     Guest                   201
     nobody                  -2
     root                    0
     tensho                  20

#### Информация о конкретном существующем пользователе

##### Показать полное имя, UID, GID и оболочку пользователя

    $ dscl . -read /Users/tensho RealName UniqueID PrimaryGroupID UserShell
    PrimaryGroupID: 20
    RealName:
     Andrew Babichev
    UniqueID: 501
    UserShell: /bin/zsh
    
или
    
    $ dscacheutil -q user -a name tensho
    name: tensho
    password: ********
    uid: 501
    gid: 20
    dir: /Users/tensho
    shell: /bin/zsh
    gecos: Andrew Babichev 
    
#### Создание нового пользователя

    $ sudo dscl . -create /Users/bob 
    $ sudo dscl . -passwd /Users/bob
    
или
    
    $ sudo sysadminctl -addUser bob -password -
    2018-09-11 22:59:41.728 sysadminctl[65397:1950525] ----------------------------
    2018-09-11 22:59:41.728 sysadminctl[65397:1950525] No clear text password or interactive option was specified (adduser, change/reset password will not allow user to use FDE) !
    2018-09-11 22:59:41.728 sysadminctl[65397:1950525] ----------------------------
    2018-09-11 22:59:41.877 sysadminctl[65397:1950525] Creating user record…
    User password:
    2018-09-11 22:59:46.724 sysadminctl[65397:1950525] Assigning UID: 503
    2018-09-11 22:59:46.882 sysadminctl[65397:1950525] Creating home directory at /Users/bob

#### Изменение пользователя

##### Добавление нового свойства

    $ sudo dscl . -append /Users/bob RealName Bobby

##### Изменение установленного свойства

    $ sudo dscl . -change /Users/bob RealName Bob
    
#### Удаление пользователя

    $ sudo dscl . -delete /Users/bob 
    
или
    
    $ sudo sysadminctl -deleteUser bob
