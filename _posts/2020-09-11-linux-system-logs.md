---
title: Linux System Logs
date: 2020-10-06
tags: linux system logs syslog journal
---

В Linux логирует почти все – от событий ядра до пользовательских действий. В стандартной папке `/var/log` находятся логи операционной системы, сервисов, утилит и приложений. Для примера вот как выглядит папка на моем [AWS workspace](https://docs.aws.amazon.com/workspaces/latest/adminguide/amazon-workspaces.html) (Amazon Linux 2/CentOS):

```
$ ls -1a /var/log
.
..
amazon
audit
boot.log
btmp
btmp-20200910
chrony
cloud-init.log
cloud-init-output.log
cron
cron-20200405
cron-20200910
dmesg
dmesg.old
falconctl.log
falcon-sensor.log
falcon-sensor.log-20200911
grubby
grubby_prune_debug
journal
lastlog
maillog
maillog-20200405
maillog-20200910
messages
messages-20200405
messages-20200910
pcoip-agent
samba
secure
secure-20200405
secure-20200910
skylight
spooler
spooler-20200405
spooler-20200910
tallylog
wtmp
Xorg.100.log
Xorg.100.log.old
yum.log
```

Тут можно найти лог-файлы `cloud-init` сервиса (`/var/log/cloud-init.log`), `cron` сервиса (`/var/log/cron`), `yum` утилиты (`/var/log/yum.log`) и многих других. Некоторые сервисы и приложения придерживаются конвенции писать логи в `/var/log` папку, а некоторые нет. Например, [SumoLogic коллектор](https://help.sumologic.com/03Send-Data/Installed-Collectors/01About-Installed-Collectors) пишет логи по месту установки в `/opt/SumoCollector/logs` по умолчанию. Однако, есть лог-файлы относящиеся непосредственно к активностям самой операционной системы:

* `/var/log/syslog` (Debian, Ubuntu) и `/var/log/messages` (RHEL, CentOS) файлы содержат информацию о глобальных активностях системы, включая сообщения загрузки.
* `/var/log/auth.log` (Debian, Ubuntu) и `/var/log/secure` (RHEL, CentOS) файлы содержат информацию о входах в систему, дейтсвия root пользователя, [PAM](https://en.wikipedia.org/wiki/Linux_PAM) вывод.
* `/var/log/kern.log` файл содержит информацию о событиях ядра (ошибки, предупреждения).

Идеологически во всех дистрибутивах Linux логирование различных системных модулей и сервисов является централизованным. Обычно это отдельно поднятый демон, который слушает на каком-то порту входящие лог-сообщения согласно определенному протоколу и записывает их в вышеупомянутые файлы. Одним из древнейших таких протоколов является Syslog. 

### Syslog

![Syslog]({{ "assets/linux-system-logs-syslog.svg" | absolute_url }})

[Syslog](https://en.wikipedia.org/wiki/Syslog) является стандартом логирования системных событий. Любой софт на вашей системе может дернуть [syslog(3)](https://linux.die.net/man/3/syslog) (libc) и отправить сообщение `syslogd` сервису, а точнее его конкретной имплементации – `rsyslogd` или `syslog-ng` . Например, в Ruby это можно сделать с помощью вызова [`Syslog::log`](https://ruby-doc.org/stdlib-2.6.1/libdoc/syslog/rdoc/Syslog.html#method-c-log) метода:

```ruby
require 'syslog'
Syslog.open("huston", Syslog::LOG_PID, Syslog::LOG_LOCAL0)
Syslog.log(Syslog::LOG_CRIT, "we have a problem")
```

В любой оболочке есть команда [`logger`](https://linux.die.net/man/1/logger), которая тоже позволяет отправить системное сообщение:

    $ logger -p local0.crit we have a problem
    
Соответственно увидеть его можно прочитав `/var/log/messages` файл:

```
$ sudo grep "we have a problem" /var/log/messages
Oct 06 09:00:00 a-2sw1oqjfy7pwo workspaces\alice: we have a problem
```

Cогласно [RFC 5424](https://tools.ietf.org/html/rfc5424) протокол Syslog сообщение содержит следующие поля (заголовки):

* Временная метка (`2020-09-11T12:12:00+0300`)
* Имя хоста (`a-2sw1oqjfy7pwo`)
* Имя источника (`workspaces\alice`)
* Приоритет (почему-то оно не отображается в сообщении ¯\\\_(ツ)\_/¯)

По умолчанию Syslog слушает на локальном Unix сокете (imuxsock), но можно легким движением руки раскомментировать соответствующие модули в `/etc/rsyslog.conf` конфигурационном файле, которые позволят слушать входящие сообщения на TCP/UDP сокетах (imtcp/imudp). 

```
$ head -n 20 /etc/rsyslog.conf
# rsyslog configuration file

# For more information see /usr/share/doc/rsyslog-*/rsyslog_conf.html
# If you experience problems, see http://www.rsyslog.com/doc/troubleshoot.html

#### MODULES ####

# The imjournal module bellow is now used as a message source instead of imuxsock.
$ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
$ModLoad imjournal # provides access to the systemd journal
#$ModLoad imklog # reads kernel messages (the same are read from journald)
#$ModLoad immark  # provides --MARK-- message capability

# Provides UDP syslog reception
#$ModLoad imudp
#$UDPServerRun 514

# Provides TCP syslog reception
#$ModLoad imtcp
#$InputTCPServerRun 514
``` 

Все это просто и понятно, но мы то с вами знаем, что многие современные Linux дистрибутивы перешли на другую логирующую систему. 

### Journal

![Journal]({{ "assets/linux-system-logs-journal.svg" | absolute_url }})

Современные CentOS, Ubuntu и другие распространенные серверные Linux дистрибутивы поставляются вместе с подсистемой инициализации и управления службами [Systemd](https://en.wikipedia.org/wiki/Systemd). Systemd имплементирует собственный сервис логирования [Journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html), который может заменять или дополнять Syslog. Journald сервис принимает сообщения из множества разных источников помимо системного вызова  `syslog(3)` – буфера ядра (kmsg aka [syslog(2)](https://www.man7.org/linux/man-pages/man2/syslog.2.html)), [sd_journal_print(3)](https://www.freedesktop.org/software/systemd/man/sd_journal_print.html), STDOUT/STDERR systemd модулей (units).

![Journal Sources]({{ "assets/linux-system-logs-journal-sources.svg" | absolute_url }})

В отличии от ограниченного набора Syslog полей, Journal предусматривает их [расширенные метаданные](https://www.freedesktop.org/software/systemd/man/systemd.journal-fields.html), структурированние и индексирование, что позволяет осуществлять более гибкий и быстрый поиск.

Давайте попробуем отправить что-то в `journald` с помощью [journald-native](https://github.com/theforeman/journald-native) Ruby гема:

```
$ gem install journald-native
```

```ruby
require 'journald/native'
Journald::Native.send "MESSAGE=we have a problem", "PRIORITY=#{Journald::LOG_CRIT}"
```

и прочитать из него с помощью `journalctl`:

```
$ journalctl -q | grep "we have a problem"
Oct 06 10:00:00 a-2sw1oqjfy7pwo workspaces\alice[28963]: we have a problem
```

Любопытно, что это же сообщение можно найти не только в журнале, но и в аутентичном `/var/log/messages`:

```
$ sudo grep "we have a problem" /var/log/messages
Oct 06 10:00:00 a-2sw1oqjfy7pwo workspaces\alice: we have a problem
```

Но как лог-записи из Journal попадают в Syslog? Обратите внимание на упомянутый конфигурационный файл для `rsyslog` выше, где подключен еще один модуль – [imjournal](https://www.rsyslog.com/doc/v8-stable/configuration/modules/imjournal.html):

```
$ModLoad imjournal # provides access to the systemd journal
```

С этим включенным модулем `rsyslog` периодически реплицирует Journal лог-записи журнала в Syslog файл. При этом структурированные поля приводятся к удовлеворимому Syslog формату. Если этого не треубется и работа идет только со стандартными Syslog полями, то лучше использовать режим локального сокета (imuxsock) по умолчанию для увеличения производительности. Однако, на практике заранее не известно, будут ли писать приложения структурированные логи или нет. Думаю поэтому этот модуль включен из коробки. 

Journal хранит свою базу данных в сжатом формате и стандартными Linux утилитами ее не прочитать, кроме как с помощью `journalctl`:  

```
$ tree /var/log/journal
/var/log/journal
└── be1d75b91fbc4a9bb1721c95179d55da
    ├── system@93fd5ed132c24d49892e6c357e377949-0000000000000001-0005a25fd7171e09.journal
    ├── system.journal
    ├── user-67163.journal
    └── user-67198.journal
$ sudo head -n 1 /var/log/journal/be1d75b91fbc4a9bb1721c95179d55da/system.journal 
  LPKSHHRHa.� p�f���SD�G�Gp��p���M��M���"��"x��x��Xo<Xo<8�+8�+XTXT��d��d������...
```

Еще одним любопытным фактом является то, что Journal поддерживает именованные области (namespaces) для логической изоляции группы логов и увеличения производительности. По умолчанию все логи обрабатываются одним `journald` сервисом в рамках одной именованной области – `default`. Но можно определить некоторые логи в собственную именованную область. 

![Journal Namespaces]({{ "assets/linux-system-logs-journal-namespaces.svg" | absolute_url }})

В следующий раз, когда я буду продумывать логирование своего приложения, эта заметка напомнит мне, что уже есть широко используемый стандарт для этих целей. И я не сомневаюсь, что тут появится дополнительная информация по мере накопления опыта и более глубокого понимания как Syslog, так и Journal.

P.S. Я тут упоролся по [PlantUML](https://plantuml.com) в последнее время. С ним делать простенькие диаграммы в разы быстрее, чем в специализированном графическом пакете вроде OmniGraffle. Попробуйте [потыкать его палочкой](https://www.planttext.com)  на досуге.  
