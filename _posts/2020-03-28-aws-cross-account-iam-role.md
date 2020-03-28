---
title: AWS Cross Account IAM Role
date: 2020-03-28
tags: aws account iam role
---

Живя в мульти-аккаунтной структуре AWS?, иногда возникает необходимость позволять IAM пользователю/роли принимать (assume) роль из другого аккаунта. Другими славами бывает нужно раздать [кросс-аккаунтный доступ](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html). Для этого нужно выполнить действия с обоих сторон – разрешить принимать целевую роль в одном аккаунте и разрешить целевой роли быть принятой из другого аккаунта. Давайте рассмотрим это на конкретном примере. Предположим, что у нас есть роль `Admin` в аккаунте `A` (`111111111111`), и мы хотим позволить этой роли принимать роль `DNSManager` в аккаунте `B` (`222222222222`) для работы с Route53 сервисом.

 ![FQDN]({{ "/assets/aws-cross-account-iam-role.svg" | absolute_url }})

Для этого нам надо добавить вот такие политики в роль `Admin` аккаунта A:

```HCL
# Политика разрешающая принимать роль DNSManager в аккаунте B
data aws_iam_policy_document assume_account_b_dns_manager_role {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    resources = ["arn:aws:iam::222222222222:role/DNSManager"]
  }
}

# Политика разрешающая федеративным пользователям Okta принимать Admin роль
data aws_iam_policy_document assume_federated_user {
  statement {
    actions = [
      "sts:AssumeRoleWithSAML",
    ]

    principals {
      type = "Federated"

      identifiers = [
        "arn:aws:iam::111111111111:saml-provider/Okta-SAML",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "SAML:aud"
      values   = ["https://signin.aws.amazon.com/saml"]
    }
  }
}

resource aws_iam_role admin {
  name               = "Admin"
  assume_role_policy = data.aws_iam_policy_document.assume_federated_user.json
}

resource aws_iam_role_policy assume_billing_policy_attachment {
  name   = "AssumeAccountBDNSManagerRole"
  role   = data.aws_iam_role.admin.name
  policy = data.aws_iam_policy_document.assume_account_b_dns_manager_role.json
}
```

и роль `DNSManager` аккаунта B:

```HCL
# Политика разрешающая принимать роль (DNSManager в аккаунте B) из аккаунта A
data aws_iam_policy_document assume_account_a {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = ["111111111111"]
    }
  }
}

resource aws_iam_role dns_manager {
  name               = "DNSManager"
  assume_role_policy = data.aws_iam_policy_document.assume_account_a.json
}

resource aws_iam_role_policy_attachment dns_manager_route53 {
  role       = aws_iam_role.dns_manager.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}
```

Многие забывают, что разрешения должны быть выданы с обеих сторон. Будьте внимательны!
