---
title: RabbitMQ Upgrade
date: 2018-03-27
tags: rabbitmq upgrade
---

Как и Rails, документация по RabbitMQ имеет одно из лучших описаний по [обновлению](https://www.rabbitmq.com/upgrade.html), которое мне доводилось видеть. Тут я бы просто хотел оставить заметку о последовательности шагов для конкретной установки на память. Хочу сразу отметить, что речь пойдет о Single-Node развертывании, т.к. кластера RabbitMQ пока не предвидится. Также стоит упомянуть, что RabbitMQ поддерживает [Blue/Green Upgrades](https://www.rabbitmq.com/blue-green-upgrade.html) без фактической остановки сервера, но такого рода подход требует создания еще одного кластера и чуть больше манипуляций вцелом. Для моего случая остановка сервера была вполне приемлема.

### Что имеем?

    $ lsb_release -a
    No LSB modules are available.
    Distributor ID:	Ubuntu
    Description:	Ubuntu 14.04.5 LTS
    Release:	14.04
    Codename:	trusty
    $ erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell
    "R16B03"
    $ dpkg -s rabbitmq-server | grep Version
    Version: 3.2.4-1

### Что хотим?

- Erlang: `20.3.x`
- RabbitMQ `3.7.x`

Совместимость версий RabbitMQ и Erlang выписаны отдельной [табличкой](https://www.rabbitmq.com/upgrade.html#rabbitmq-version-compatibility).

### Как получить?

Добавить в файл `/etc/apt/sources.list` ссылки на репозитории Erlang и RabbitMQ:

    deb http://packages.erlang-solutions.com/ubuntu trusty contrib
    deb https://dl.bintray.com/rabbitmq/debian trusty main

Добавить публичные ключи для проверки подписей дистрибутивов:

    $ wget -O- http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -
    $ wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add -

Обновить реестр менеджера пакетов apt:

    $ sudo apt-get update

Есть один ньюанс связанный с необходимостью проводить некоторые обновления поэтапно. В описанной установке нужно сначала провести RabbitMQ `3.2.4 (R13B03 – R16B03) –> 3.6.14 (R16B03 – 20.1.x)`, а потом `3.6.14 –> 3.7.x (19.3 – 20.3.x)` (в скобках указана совместимая Erlang версия). О миграции внутренней базы данных, конфигурационных файлов и остальных внутренностей RabbitMQ позабоится сам.

Однако, о чем RabbitMQ не беспокоится, так это о бекапе вашей топологии и сообщений. Как и в любой современной системе рекомендуется предварительно обновлению сделать бекап. Топологию можно выгрузить через Management Web UI интерфейс, в самом низу вкладки "Overview" одним нажатием кнопки "Download broker definitions" или запустить `rabbitmqadmin` команду:

    $ rabbitmqadmin --vhost production --username=admin --password=T0p5ecret export /mnt/data/backup/rabbit.definitions.json

Стандартно сообщения лежат в `RABBITMQ_MNESIA_DIR` ([`;RABBITMQ_MNESIA_BASE/$RABBITMQ_NODENAME`](https://www.rabbitmq.com/relocate.html#unix)) и единственный способ их сохранить – сделать копию всей папки RabbitMQ хоста:

    $ cp -r /var/lib/rabbitmq/mnesia/rabbit@ec2-host-1 /mnt/data/backup

Установить крайний Erlang

    $ sudo apt-get install -y erlang

Установить RabbitMQ 3.6.14 (нет в Bintray, есть в PackageCloud)

    $ curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh | sudo bash
    Detected operating system as Ubuntu/trusty.
    Checking for curl...
    Detected curl...
    Checking for gpg...
    Detected gpg...
    Running apt-get update... done.
    Installing apt-transport-https... done.
    Installing /etc/apt/sources.list.d/rabbitmq_rabbitmq-server.list...done.
    Importing packagecloud gpg key... done.
    Running apt-get update... done.

    The repository is setup! You can now install packages.
    $ sudo apt-cache madison rabbitmq-server | grep 3.6.14
    rabbitmq-server |   3.6.14-1 | https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ trusty/main amd64 Packages
    $ sudo apt-get install -y rabbitmq-server=3.6.14-1
    ...
     * Stopping message broker rabbitmq-server [ OK ]
    ...
     * Starting message broker rabbitmq-server [ OK ]

Установить крайний RabbitMQ

    $ sudo apt-get install rabbitmq-server
    ...
     * Stopping message broker rabbitmq-server [ OK ]
    ...
     * Starting message broker rabbitmq-server [ OK ]

Проверить версии пакетов

    $ erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell
    20.3
    $ dpkg -s rabbitmq-server | grep Version
    Version: 3.7.4-1
