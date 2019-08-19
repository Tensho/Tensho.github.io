---
title: MacOS Shared Libraries
date: 2019-08-19
tags: macos shared library lib
---

Большинство программ в Unix используют C библиотеки. Связать программу с библиотекой можно статически или динамически. Статически связанная библиотека запекается в один бинарный (исполняемый) файл увеличивая его размер. Динамически связанная библиотека (shared library) вызывается в момент исполнения программы и обязана находится в заранее известном месте. Такие библиотеки используются множеством программ экономя дисковое пространнство от постоянного дублирования кода от программы к программе. Примерами популярных динамических библиотек являются `openssl` (ssl), `libpcre` (regexp), `zlib` (gzip), `readline` (command-line editing), `libxml2` (XML parsing).

Linux позволяет вывести список используемых динамических библиотек конкретной программой с помощью утилиты `ldd`. Для MacOS подобной утилитой является `otool`. Давайте посмотрим на то, как две самые распространенные реляционных СУБД `mysql` и `postgres` шарят   одну и ту же динамическую библиотеку `openssl`:

```
$ uname
Darwin
$ brew install postgresql > /dev/null
$ brew install mysql > /dev/null
$ which postgres | xargs otool -L
/usr/local/bin/postgres:
  /usr/lib/libxml2.2.dylib (compatibility version 10.0.0, current version 10.9.0)
  /usr/lib/libpam.2.dylib (compatibility version 3.0.0, current version 3.0.0)
  /usr/local/opt/openssl/lib/libssl.1.0.0.dylib (compatibility version 1.0.0, current version 1.0.0)
  /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib (compatibility version 1.0.0, current version 1.0.0)
  /System/Library/Frameworks/Kerberos.framework/Versions/A/Kerberos (compatibility version 5.0.0, current version 6.0.0)
  /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1252.250.1)
  /System/Library/Frameworks/LDAP.framework/Versions/A/LDAP (compatibility version 1.0.0, current version 2.4.0)
  /usr/local/opt/icu4c/lib/libicui18n.64.dylib (compatibility version 64.0.0, current version 64.2.0)
  /usr/local/opt/icu4c/lib/libicuuc.64.dylib (compatibility version 64.0.0, current version 64.2.0)
$ which mysql | xargs otool -L
/usr/local/bin/mysql:
  /usr/lib/libedit.3.dylib (compatibility version 2.0.0, current version 3.0.0)
  /usr/local/opt/openssl/lib/libssl.1.0.0.dylib (compatibility version 1.0.0, current version 1.0.0)
  /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib (compatibility version 1.0.0, current version 1.0.0)
  /usr/lib/libc++.1.dylib (compatibility version 1.0.0, current version 400.9.4)
  /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1252.200.5)
```

Как видно из вывода версии совместимости соблюдены и блягодаря этому оба пакета баз данных могут успешно использовать одну и ту же библиотеку SSL протокола. Так же обратите внимание, что стандартный `postgres` под MacOS использует системные библиотеки `Kerberos` и `LDAP`, в то время как `mysql` обходится без осевых библиотек по-умолчанию (вероятно аутентификация идет в виде плагинов и доставляется отдельно).

### Полезные ссылки

- [ROSETTA STONE](http://bhami.com/rosetta.html) – чумавое сравнение утилит между разными \*nix дистрибутивами
- [Understanding Shared Libraries In Linux](https://www.tecmint.com/understanding-shared-libraries-in-linux)
