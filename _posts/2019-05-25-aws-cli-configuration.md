---
title: AWS CLI Configuration
date: 2019-05-25
tags: aws cli configuration
---

Краткая шпаргалка по [конфигурации AWS CLI клиента](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) на локальной машине.

Различные наборы конфигурации группируются в рамках профилей (`profile`).

### Что конфигурировать?

- `aws_access_key_id` и `aws_secret_access_key` (сладкая парочка Twix)
- `output format` – `json` (default), `text`, `table` – формат вывода результатов по умолчанию
- `region` – AWS регион по умолчанию

### Как конфигурировать?

#### Быстро

Редактировать файлы `~/.aws/credentials` и `~/.aws/config` вручную, через vim (так кошерней).

#### Очень быстро

    $ aws configure set profile.kaori.aws_access_key_id FAKE4JIGTOYI64PIPZZZ
    $ aws configure set profile.kaori.aws_secret_access_key FAKE0fri2ZZ8iB33xJMgl6TapB2lFE3rpmFtFYXZ

#### Ультра быстро

    $ aws configure
    $ aws configure --propfile kaori

### Приоритет источников конфигурации

1. [Опции CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-options.html) (`--profile`, `--region`, `--output`)
2. [Перменные окружения](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`)
3. [Файлы `~/.aws/credentials` и `~/.aws/config`](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
4. IAM Роль для ECS контейнера или [EC2 инстанса](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-metadata.html)

### Как использовать?

    $ aws ec2 describe-instances --profile kaori --region eu-west-1 --output table
    $ AWS_DEFAULT_PROFILE=kaori AWS_DEFAULT_REGION=eu-west-1 AWS_DEFAULT_OUTPUT=table aws ec2 describe-instances

### Что еще нужно знать?

- Сладкая парочка Twix всегда ассоциирована с конкретным IAM пользователем или ролью

- Все HTTP запросы к AWS API зашифрованы с учетом даты и времени, поэтому важно иметь корректное время на рабочей машине

- Для EC2 инстансам и ECS контейнерам кошерно раздавать доступ через IAM роли. Благодаря такому подходу можно избежать необходимости ротировать перманентные ключи, а использовать исключительно временно предоставленные STS сервисом.

- Все официальные AWS SDK (клиенты) работают с паролями/явками по такому же принципу, как и стандартный питоновский AWS CLI

- Есть небольшая разница в форматировании секций профайлов

```
# ~/.aws/credentials

[example]
aws_secret_access_key = EXAMPLE
aws_access_key_id = EXAMPLE
```

vs

```
# ~/.aws/config

[profile example]
aws_secret_access_key = EXAMPLE
aws_access_key_id = EXAMPLE
```
