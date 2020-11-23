---
title: AWS IAM Organization Principal Condition
date: 2020-11-23
tags: aws iam organization principal
---

Искренне считаю, что IAM заслуживает быть выделенным в отдельную специализацию в рамках AWS. Столько разных концепций и ньюансов я еще не встречал ни в одном другом амазоновском сервисе. Наверное когда все их выучишь и набьешь руку, то обеспечение [принципа минимальных привилегий](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege) в инфраструктуре будет простой рутиной. Но пока я еще не встречал нашего брата или сестру, которые бы с легкостью гибко управляли IAMом. 

На днях мне попался любопытный кейс с превышением лимита вложенных в IAM роль политик в рамках мульти-аккаунтной инфраструктуры. Предположим, что у нас есть инфраструктурный компонент мониторинга, который обеспечивает доступ Grafana сервиса к AWS CloudWatch сервису как источнику данных.

![AWS IAM Grafana CloudWatch]({{ "assets/aws-iam-grafana-cloudwatch.svg" | absolute_url }})

Этот компонент раскатывает дочернюю IAM роль (агент) в каждом целевом аккаунте с разрешениями доступа к логам и метрикам CloudWatch в нем. В свою очередь каждую такую роль принимает родителськая IAM роль в мониторинг аккаунте.

При добавлении нового аккаунта в организацию подкидывается новая вложенная политика. Напомню, что для [кросс-аккаунтного принятия роли требуется укзать `sts:AssumeRole` разрешение на обоих концах]({% post_url 2020-03-28-aws-cross-account-iam-role %}). Вот так может выглядеть Terraform код описывающий это хозяйство:

###### Monitoring Account

```hcl
################################################################################
# Grafana main IAM role in monitoring account, which assumes agent IAM role in the target account
################################################################################
resource aws_iam_role grafana {
  name               = "grafana"
  assume_role_policy = data.aws_iam_policy_document.ecs_sts_assume_role.json
}

data aws_iam_policy_document ecs_sts_assume_role {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
```

###### Target Account

```hcl
################################################################################
# Grafana agent IAM role
################################################################################
resource aws_iam_role grafana_cloudwatch_agent {
  name               = "grafana-cloudwatch-agent"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role.json
}

data aws_iam_policy_document grafana_assume_role {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.grafana.arn]
    }
  }
}

data aws_iam_role grafana {
  provider = aws.monitoring

  name     = "grafana"
}

################################################################################
# Extend Grafana main IAM role with inline policy, which allows to assume agent IAM role
################################################################################
resource aws_iam_role_policy allow_assume_grafana_cloudwatch_agent {
  provider = aws.monitoring

  name     = data.aws_iam_account_alias.current.account_alias
  role     = data.aws_iam_role.grafana.id
  policy   = data.aws_iam_policy_document.allow_assume_grafana_cloudwatch_agent.json
}

data aws_iam_policy_document allow_assume_grafana_cloudwatch_agent {
  provider = aws.monitoring

  statement {
    actions = ["sts:AssumeRole"]

    resources = [aws_iam_role.grafana_cloudwatch_agent.arn]
  }
}

data aws_iam_account_alias current {}
```

Тут мы расширяем список аккаунтов для родительской роли на стороне компонента. И все хорошо с таким подходом, пока количество аккаунтов не увеличевается до таких размеров, что соответствующее количество вложенных политик превышает стандартный лимит политики в 10240 байта. Для обеспечения дальнейшего масштабирования требуется рефакторинг. И видимо как раз для таких случаев в IAM добавлено весьма полезное [условие `aws:PrincipalOrgID`](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-principalorgid). Оно позволяет проверить, принадлежит ли доверитель (Principal) к AWS организации. С этой фичей можно не перечислять каждый целевой аккаунт в разрешениях политики, а просто обозначить шаблон доверителя с условием принадлежности аккаунта к организации.

###### Monitoring Account

```hcl
################################################################################
# Grafana main IAM role, which assumes agent IAM role in any organization account
################################################################################
resource aws_iam_role_policy allow_assume_grafana_cloudwatch_agent {
  name     = "allow-assume-cloudwatch-agent"
  role     = aws_iam_role.grafana.id
  policy   = data.aws_iam_policy_document.allow_assume_grafana_cloudwatch_agent.json
}

data aws_iam_policy_document allow_assume_grafana_cloudwatch_agent {
  statement {
    actions = ["sts:AssumeRole"]

    resources = ["arn:aws:iam::*:role/grafana-cloudwatch-agent"]

    condition {
      test     = "StringEquals"
      variable = "AWS:PrincipalOrgID"

      values = [data.aws_organizations_organization.organization.id]
    }
  }
}

data aws_organizations_organization organization {
  provider = aws.billing
}
```

###### Target Account

```hcl
################################################################################
# Grafana agent IAM role
################################################################################
resource aws_iam_role grafana_cloudwatch_agent {
  name               = "grafana-cloudwatch-agent"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role.json
}

data aws_iam_policy_document grafana_assume_role {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.grafana.arn]
    }
  }
}

data aws_iam_role grafana {
  provider = aws.monitoring

  name     = "grafana"
}

# We don't need to extend Grafana IAM role with inline policies anymore. 
```

При таком подходе нам не нужно изменять доверительный список родительской роли каждый раз, когда добавляется новый аккаунт с дочерней ролью.

AWS достаточно активно расширяет фичи IAM для работы в рамках мульти-аккаунтной организации. Поэтому стоит вложится в их изучение заранее, если на горизонте шагает огромная армия аккаунтов. Кстати многие амазоновские сервисы безопасности (и не только) так же добавляют возможность централизованно собирать данные в главный аккаунт. Но об этом уже в другой раз.
