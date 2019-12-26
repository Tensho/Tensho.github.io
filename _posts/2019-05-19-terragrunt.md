---
title: Terragrunt
date: 2019-05-19
tags: terragrunt terraform aws
---

Автор [Terragrunt](https://github.com/gruntwork-io/terragrunt) описывает его как тонкую обертку над [Terraform](https://github.com/hashicorp/terraform) позволяющую отдраить код инфраструктуры, сделать ее мягкой и шелковистой. Я же хочу сделать акцент на другом. Terragrunt представляет собой каркас, если хотите фреймворк, который задает определенные рамки разработчикам и распространяет своего рода подход конвенции вместо конфигурации среди команды. Для большинства Rails разработчиков такой подход вполне понятен и естественен, а его преимущества уже много раз оценены в ежедневной работе. Однако, для в DevOps мире вокруг меня все немного иначе и некоторые люди не сразу приходят к осознанию пользы данного подхода.

Я не вижу смысла перечислять здесь мотивы и все фичи, которые предлагает Terragrunt, т.к. с этим прекрасно справляется официальный [README](https://github.com/gruntwork-io/terragrunt#terragrunt) документ в репозитори проекта. В данной заметке я хотел бы поговорить больше о том, как лучше всего организовать структуру папок и файлов при работе с множеством AWS аккаунтов и регионов при помощи Terragrunt. К сожалению найти что-то стоящее по данной теме в Интернете не так уж и просто. Лучшее что мне приходлось читать на эту тему – книга  ["Terraform: Up & Running"](https://www.terraformupandrunning.com) за авторством [Евгения Брикмана](https://github.com/brikis98). Должен сразу сказать, что у меня нет еще достаточного практического опыта с Terragrunt, поэтому все мои умозаключения более теоритические. Возможно в будущем я дополню или вообще изменю выбранный мной вариант. Но что я точно могу сказать уже сейчас – многие фишки Terragrunt мне приходилось имплементировать самому в виде Bash и Ruby скриптов до того, как я узнал о существовании данного инструмента.

Автор Terragrunt предлагает разделять весь код на 2 репозитория – один для Terraform модулей (`terraform-modules`), другой для Terraform переменных, отражающих текущее состояние инфраструктуры (`terraform-spaces`). В принципе так делать не обязательно (можно вынести модули просто в отдельную папку), но желательно для более явного разделения ответственностей. По поводу ценности выделения Terraform кода в модули уже сломано немало копий и я думаю читатель без проблем найдет соответствующую информацию в Интернете. Здесь мы берем модульный подход как аксимому.

### terraform-modules

В общем структура `terraform-modules` выглядит так:

```
provider (aws)
  application_or_common_provider_service (awesome-app, brilliant-service, iam, cloudtrail)
    main.tf
    outputs.tf
    variables.tf
```

Уровень `provider` выделен для того, чтобы в будущем добавлять папки с модулями использующими другие провайдеры. Например, в ближайшем будущем я хочу управлять пользователями и репозиториями [GitHub через Terraform](https://www.terraform.io/docs/providers/github/index.html). Одним из вариантов может служить разбиение папок сугубо по сервисам провайдера. Например, для AWS это будет выглядеть как-то так:

```
aws
  cloudfront
    main.tf
    outputs.tf
    variables.tf
  ec2
    main.tf
    outputs.tf
    variables.tf
  iam
    main.tf
    outputs.tf
    variables.tf
  rds
    main.tf
    outputs.tf
    variables.tf
  s3
    main.tf
    outputs.tf
    variables.tf
  ...
```

Изначально мне такой подход казался самым логичным, т.к. при обсуждении с коллегами вопросов инфраструктуры я чаще оперирую понятиями конкретных сервисов AWS в разрезе какого-нибудь приложения. Другими словами мне проще описать решение для развертывания нового приложения так: "Добавь такой-то RDS инстанс, такой-то EC2 инстанс, такой-то ASG, такой-то ALB, такой-то субдомен в Route53". Но позже я понял, что для привления людей к самостоятельному использованию написанных мною модулей нужно описывать их с точки зрения конечных пользователей – разработчиков приложения! И обычно разработчики приложений максимум согласны определить конфигурацию конкретного приложения или сервиса, но никак не намерены вникать во все необходимые для этого компоненты облака. Неделей позже тоже самое было отмечено [Антоном Бабенко](https://github.com/antonbabenko) на [HashiCorp Meetup #5](https://www.meetup.com/Kyiv-HashiCorp-User-Group/events/260640884/) в Киеве: "Есть 2 вида пользователей Terraform – те кто пишут модули и те кто их потом используют. Первым всегда нужно думать об удобстве вторых". В моем случае долго время я выполнял обе роли и поэтому мой взгляд был немного замылен.

В итоге внутри папки провайдера ресурсы группируются по папкам приложений и сервисов. Конечно всегда будут какие-то общие ресурсы для нескольких/всех приложений/сервисов и их придется выделять обособленно. Но в целом команда DevOps работающих с Terraform/Terragrunt должна стремится к контексту поддерживаемого приложения.

Пример:

```
aws
  apps
    app-1
      main.tf # = ec2 + rds + route53
      outputs.tf
      variables.tf
    app-2
      main.tf # = ecs + dynamo + route53
      outputs.tf
      variables.tf
    service-1
      main.tf # = ec2 + rds + sqs
      outputs.tf
      variables.tf
    service-2
      main.tf # = ecs + dynamo + sqs
      outputs.tf
      variables.tf
  iam
    main.tf
    outputs.tf
    variables.tf
  vpc
    main.tf
    outputs.tf
    variables.tf
  elasticache
    main.tf
    outputs.tf
    variables.tf

```

### terraform-spaces

`spaces` – это аллюзия на стандартные [terraform workspaces](https://www.terraform.io/docs/state/workspaces.html). Представленная ниже организация позволяет полностью избавится от необходимости использовать workspaces. "Но что плохого в workspaces?" – сросите вы. Я лично убедился, что регулярные переключения между workspaces заставляют лишний раз концентрировать внимание напрягая мозг, даже если это делается полу-автоматически через какие-либо скрипты. Цена ошибки неправильно выбранного workspace очень высока, т.к. может положить весь production на раз. Но самое страшное другое – workspaces "невидимы", они никак не присутствуют в репозитории кода. А это нарушение золотого правила IaC – то, что мы видим своими глазами на `master` ветке должно отражать 1:1 состояние `production` инфраструктуры. Все тот же уважаемый господин Бабенко считает, что HashiCorp придумали workspaces исключительно для Terraform Enterprise (да, да, тот самый кровавый) и притянули его в свободную версию за зря. Единственным оправданием workspaces может быть использование его как feature branch. Но как по мне, лучше завести отдельный AWS development аккаунт для разработки и экспериментов, вплоть до одной штуки для каждого участника команды.

В контексте AWS и Terragrunt структура выглядит так:

```
aws_account
  global
    common_aws_service_per_account
  aws_region
    global
      common_aws_service_per_region
    environment
      application_or_common_aws_service_per_environment
        ...
```

И пример:

```
ganymede
  global
    iam
      terraform.tfvars
    route53
      terraform.tfvars
    cloudtrail
      terraform.tfvars
  eu-west-1
    global
      route53
        terraform.tfvars
    production
      apps
        app-1
          terraform.tfvars
        app-2
          terraform.tfvars
        service-1
          terraform.tfvars
        service-2
          terraform.tfvars
      vpc
        terraform.tfvars
      elasticache
        terraform.tfvars
  ca-central-1
    global
      route53
        terraform.tfvars
    production
      apps
        app-1
          terraform.tfvars
        app-2
          terraform.tfvars
        service-1
          terraform.tfvars
        service-2
          terraform.tfvars
      vpc
        terraform.tfvars
      elasticache
        terraform.tfvars
callisto
  global
    iam
      terraform.tfvars
    route53
      terraform.tfvars
    cloudtrail
      terraform.tfvars
  eu-west-1
    global
      route53
        terraform.tfvars
    staging
      apps
        app-1
          terraform.tfvars
        app-2
          terraform.tfvars
        service-1
          terraform.tfvars
        service-2
          terraform.tfvars
      vpc
        terraform.tfvars
      elasticache
        terraform.tfvars
  ca-central-1
    global
      route53
        terraform.tfvars
    staging
      apps
        app-1
          terraform.tfvars
        app-2
          terraform.tfvars
        service-1
          terraform.tfvars
        service-2
          terraform.tfvars
      vpc
        terraform.tfvars
      elasticache
        terraform.tfvars
himalia
  global
    iam
      terraform.tfvars
    route53
      terraform.tfvars
    cloudtrail
      terraform.tfvars
  eu-west-1
    global
      route53
        terraform.tfvars
    development
      apps
        app-1
          terraform.tfvars
        app-2
          terraform.tfvars
        service-1
          terraform.tfvars
        service-2
          terraform.tfvars
      vpc
        terraform.tfvars
      elasticache
        terraform.tfvars
```

Здесь луны Юпитера (кто как не называет аккаунты – породы кошек, горные вершин, буквы греческого алфавита) представляют названия AWS аккаунтов для `production`, `staging` и `development` окружений. Дополнительные аккаунты и окружения можно добавить легким копированием уже существующих. Например, если требуется разделить `development` окружение на несколько независимых команд разработчиков, то организация папок может выглядеть так:

```
...
himalia
  global
    iam
      terraform.tfvars
    route53
      terraform.tfvars
    cloudtrail
      terraform.tfvars
  eu-west-1
    global
      route53
        terraform.tfvars
    development-alpha-team
      apps
        app-1
          terraform.tfvars
        app-2
          terraform.tfvars
        service-1
          terraform.tfvars
        service-2
          terraform.tfvars
      vpc
        terraform.tfvars
      elasticache
        terraform.tfvars
    development-beta-team
      apps
        app-1
          terraform.tfvars
        app-2
          terraform.tfvars
        service-1
          terraform.tfvars
        service-2
          terraform.tfvars
      vpc
        terraform.tfvars
      elasticache
        terraform.tfvars
```

Аналогичные телодвижения нужны для дополнительного `staging` окружения, скажем, для замера долгоиграющей миграции схемы БД и данных:

```
...
callisto
  global
    iam
      terraform.tfvars
    route53
      terraform.tfvars
    cloudtrail
      terraform.tfvars
  eu-west-1
    global
      route53
        terraform.tfvars
    staging
      apps
        app-1
          terraform.tfvars
        app-2
          terraform.tfvars
        service-1
          terraform.tfvars
        service-2
          terraform.tfvars
      vpc
        terraform.tfvars
      elasticache
        terraform.tfvars
    staging-measure-companies-migration
      apps
        app-1
          terraform.tfvars
        app-2
          terraform.tfvars
        service-1
          terraform.tfvars
        service-2
          terraform.tfvars
      vpc
        terraform.tfvars
      elasticache
        terraform.tfvars
...
```

В заключении хочу подчеркнуть еще раз, что такая структура позволяет очень быстро понять, что творится в `production ` облаке глядя только на код в GitHub. А по каким критериям организован ваш Terraform код?

### Cписок ресурсов

- ["Terraform: Up & Running"](https://www.terraformupandrunning.com/)
- https://github.com/gruntwork-io/terragrunt-infrastructure-modules-example
- https://github.com/gruntwork-io/terragrunt-infrastructure-live-exampl
- https://github.com/antonbabenko/terragrunt-reference-architecture
