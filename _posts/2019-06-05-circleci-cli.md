---
title: CircleCI CI
date: 2019-06-05
tags: circleci cli
---

Наткнувшись на неработающую ссылку в своем старом посте я задумался о добавлении проверок корректности сгенерированных ранее HTML страниц с помощью [html-proofer](). Обычно такого рода тесты неплохо иметь в рамках CI, чтобы вся команда могла видеть текущий статус по изменениям. В моем же соло случае это автоматизация локальных запусков тестов. В принципе такие штуки можно подвешивать на git hook с помощью множества разнообразных оберток ([overcommit](), [lefthook](https://github.com/Arkweid/lefthook)), но мне хочется освежить знания по CircleCI. 

Что такое CircleCI в общем и как выглядит его конфигурация в частности можно почитать в прекрасной [официальной докуентации](https://circleci.com/docs/2.0). Для удобной работы с сервисом компания предоставляет [CircleCI CLI](https://circleci.com/docs/2.0/local-cli/), который может следующие:

- Отладка и валидация кофигурации (`config.yml`)
- Запуск задач локально
- Вызовы CircleCI API
- Работа с [орбами](https://circleci.com/docs/2.0/orb-intro) 

Как раз к CLI я бы и хотел присмотреться по-ближе. Для моей задачи будет использоваться вот такой `config.yml`:

```YAML
version: 2.1

executors:
  ruby-container:
    docker:
      - image: circleci/ruby:2.5.4

jobs:
  build:
    description: Build
    executor: ruby-container
    environment:
      - NOKOGIRI_USE_SYSTEM_LIBRARIES: true
    steps:
      - setup_remote_docker
      - checkout
      - run:
          command: bundle install --path vendor/bundle
      - run:
          command: bundle exec jekyll build
      - persist_to_workspace:
          root: .
          paths:
            - ./*
  test:
    description: Test
    executor: ruby-container
    steps:
      - setup_remote_docker
      - attach_workspace:
         at: .
      - run:
          command: bundle check --path vendor/bundle
      - run:
          command: bundle exec htmlproofer ./_site --assume_extension --disable_external --check_external_hash --check_html --check_favicon --check_opengraph --check_img_http

workflows:
  main:
    jobs:
      - build
      - test:
          requires:
            - build
``` 

### Установка (MacOS)

    $ brew install --ignore-dependencies circleci
    
Для атуентификации используется [персональные API токены](https://circleci.com/account/api) идентично множеству других SaaS. Прописываем токен на своей машине:

    $ cirlceci setup --token fake1c73333bdeb28cca524667052777bed90123

По аналогии с AWS CLI (`~/.aws`) файл с секретами сохраняется в `~/.circleci`.
    
### Валидация `config.yml`

    $ circleci config validate
    Config file at .circleci/config.yml is valid.
    
CircleCI CLI позволяет существенно сократить время первичной настройки сервиса благодаря отладке на локальной машине.

### Процессинг `config.yml`

    $ circleci config process .circleci/config.yml > .circleci/config.2.0.yml
    version: 2
    jobs:
      build:
        docker:
        - image: circleci/ruby:2.5.4
    ...

Когда используются орбы (пакет с обособленной конфигурацией), то удобно сделать их инлайн в один файл. Это позволит увидеть общую картину и более наглядно проверить результирующий файл.

Данная команда также сконвертирует конфиг с версии `2.1` в `2.0` для локального запуска задач.

### Локальный запуск задач

    $ circleci local execute --config.2.0.yml --job build
    Docker image digest: sha256:bed7a55fb94123dac4796ad12ebdd89f14089e34ffc6f272c9d441f456444ba6
    ====>> Spin up Environment
    Build-agent version 1.0.11774-17301ec6 (2019-05-31T04:08:10+0000)
    Docker Engine Version: 18.09.2
    Kernel Version: Linux a5d00768af47 4.9.125-linuxkit #1 SMP Fri Sep 7 08:20:28 UTC 2018 x86_64 Linux
    Starting container circleci/ruby:2.5.4
      using image circleci/ruby@sha256:9683757d38ca76c15e28f566256ea75736daf5dd223f5c0fb223b60946e00505
    
    Using build environment variables
      BASH_ENV=/tmp/.bash_env-localbuild-1559720196
      CI=true
      CIRCLECI=true
      CIRCLE_BRANCH=add-ci
      CIRCLE_BUILD_NUM=
      CIRCLE_JOB=build
      CIRCLE_NODE_INDEX=0
      CIRCLE_NODE_TOTAL=1
      CIRCLE_REPOSITORY_URL=git@github.com:Tensho/Tensho.github.io.git
      CIRCLE_SHA1=e1262a5e3152d5809765ad56030068b64b420e25
      CIRCLE_SHELL_ENV=/tmp/.bash_env-localbuild-1559720196
      CIRCLE_WORKING_DIRECTORY=~/project
    
    ====>> Setup a remote Docker engine
    Using local docker engine bind-mounted
    ====>> Checkout code
      #!/bin/bash -eo pipefail
    mkdir -p /home/circleci/project && cd /tmp/_circleci_local_build_repo && git ls-files | tar -T - -c | tar -x -C /home/circleci/project && cp -a /tmp/_circleci_local_build_repo/.git /home/circleci/project
    ====>> bundle install --path vendor/bundle
      #!/bin/bash -eo pipefail
    bundle install --path vendor/bundle
    Fetching gem metadata from https://rubygems.org/.........
    Fetching concurrent-ruby 1.1.5
    Installing concurrent-ruby 1.1.5
    ...
    Fetching html-proofer 3.10.2
    Installing html-proofer 3.10.2
    Bundle complete! 4 Gemfile dependencies, 89 gems now installed.
    Bundled gems are installed into `/usr/local/bundle`
    ====>> bundle exec jekyll build
      #!/bin/bash -eo pipefail
    bundle exec jekyll build
    Configuration file: /home/circleci/project/_config.yml
    Invalid theme folder: _includes
    Invalid theme folder: _includes
                Source: /home/circleci/project
           Destination: /home/circleci/project/_site
     Incremental build: disabled. Enable with --incremental
          Generating...
           Jekyll Feed: Generating feed for posts
       GitHub Metadata: No GitHub API authentication could be found. Some fields may be missing or have incorrect data.
                        done in 1.331 seconds.
     Auto-regeneration: disabled. Use --watch to enable.
    ====>> Persisting to Workspace (skipped)
    Warning: skipping this step: Missing workflow workspace identifiers, this step must be run in the context of a workflow
    Success!
    
К сожалению, есть очевидные ограничения:

- Не поддерживается `machine` (VM) платформа запуска 
- Не поддерживается `workflow` в виду распараллеливания билдов на множество машин
- Не поддерживается кеширование
- Секретные (зашифрованные) переменные окружения нужно передавать явно через `--env VAR1=FOO -e VAR2=BAR` опцию
    
### Список доступных CLI команд

- `circleci`
  - `config`
    - `pack` – упаковка конфига в единый файл
    - `process` – процессинг конфиг файла
    - `validate` – валидация конфиг файла
  - `diagnostic` – проверить статус CircleCI CLI
  - `help`
  - `local`
    - `execute` – отладка задач на локальной машине
  - `namespace` – ?
    - `create` – ?
  - `orb`
    - `create` – создание орба в указанном пространстве имен
    - `info` – метаданные орба
    - `list` – список орбов
    - `process ` – валидация орба
    - `publish ` - публикация орба в реестр
    - `source  ` – исходник орба
    - `validate` – валидация `orb.yml`
  - `query` – GraphQL API запрос
  - `setup` – установка CLI токена
  - `update` - обновить пакет CLI (если установка была через Homebrew, то нужно обновлять через него)
  - `version` – версия CLI
