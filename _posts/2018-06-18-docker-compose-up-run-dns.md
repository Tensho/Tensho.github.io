---
title: Любопытная разница в работе DNS для docker-compose run и docker-compose up
date: 2018-06-18
tags: docker networking compose docker-compose dns alias
---

В рамках перехода с Phantomjs на Headless Chrome (+ ChromeDriver) end-to-end тестирование текущего проекта и попутной докеризации мне пришлось немножко разобраться с тем, как [Docker Compose](https://docs.docker.com/compose/overview/) чудесным образом позволяет ссылаться контейнерам друг на друга по доменным именам. Рассмотрим для примера конкретный `docker-compose.yml` файл конфигурации:

```
version: '3'

services:
  alpha:
    image: alpine
    command: ["/bin/sh", "-c", "while sleep 3600; do :; done"]

  beta:
    image: alpine
    command: ["/bin/sh", "-c", "while sleep 3600; do :; done"]
```

Есть два сервиса **alpha** и **beta**. Если мы запустим их с помощью команды `docker-compose up`, то оба сервиса могу разрезолвить доменные имена друг друга:

```
$ docker-compose -p project up -d
$ docker-compose -p project exec alpha ping -q -c 1 beta
PING beta (172.20.0.3): 56 data bytes

--- beta ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.081/0.081/0.081 ms
$ docker-compose -p project exec beta ping -q -c 1 alpha
PING alpha (172.20.0.2): 56 data bytes

--- alpha ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.117/0.117/0.117 ms
$ docker-compose -p projec down -t 1
```

Но всем меняется, когда мы пытаемся запустить сервисы через `docker-compose run`:

```
$ docker-compose -p project run -d alpha
project_alpha_run_1
$ docker-compose -p project run -d beta
project_beta_run_1
$ docker-compose -p project run alpha ping -q -c 1 beta
ping: bad address 'beta'
$ docker-compose -p project run beta ping -q -c 1 alpha
ping: bad address 'alpha'
$ docker-compose -p project down -t 1
```

Доменные имена не добавляются в дефолтный DNS резолвер, который находится внутри Docker Engine. Ситуация немного лучше, когда добавляется директива `depends_on`:

```
version: '3'

services:
  alpha:
    image: alpine
    command: ["/bin/sh", "-c", "while sleep 3600; do :; done"]
    depends_on:
      - beta

  beta:
    image: alpine
    command: ["/bin/sh", "-c", "while sleep 3600; do :; done"]
```

и запускаем тот же эксперимент:

```
$ docker-compose -p project run -d alpha
project_alpha_run_1
$ docker-compose -p project run alpha ping -q -c 1 beta
Starting project_beta_1 ... done
PING beta (172.21.0.2): 56 data bytes

--- beta ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.095/0.095/0.095 ms
$ docker-compose -p project run beta ping -q -c 1 alpha
ping: bad address 'alpha'
```

Как видно зависимый сервис автоматически добавляется в DNS резолвер. Но что делать, если нужны DNS записи обоих сервисов, но при этом хочется запускать команду `docker-compose run`? Ответом на этот вопрос служи специальный малоупоминаемый флаг [`--use-aliases`](https://github.com/docker/compose/pull/5725):

 ```
$ docker-compose -p project run -d --use-aliases alpha
project_alpha_run_1
$ docker-compose -p project run alpha ping -q -c 1 beta
Starting project_beta_1 ... done
PING beta (172.21.0.2): 56 data bytes

--- beta ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.106/0.106/0.106 ms
$ docker-compose -p project run beta ping -q -c 1 alpha
PING alpha (172.21.0.3): 56 data bytes

--- alpha ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.112/0.112/0.112 ms
 ```

Прочитав цепочку GitHub Issues посвященных этой проблеме я понял, что данный флаг не включается по умолчанию, ибо так задумано авторами изначально. В большинстве случаев задавать обратные зависимости не требуется. Откровенно говоря я не вижу больших накладных расходов на добавление всех сервисов в DNS резолвер по умолчанию, но возможно это нарушает концепцию минимальной полезной конфигурации для инструмента. Однако, в некоторых случаях это крайне необходимо. Как я писал в начале, мне потребовалось, чтобы приложение с feature (e2e) тестами в контейнере могло подсоединяться к сервису Selenium Grid в отдельном контейнере по доменному имени, и в тоже время запросы бразуера в рамках этих тестов шли на контейнере с приложением ссылаясь на его доменное имя. Как раз для такого случая полезно знать о **`--use-aliases`**.
