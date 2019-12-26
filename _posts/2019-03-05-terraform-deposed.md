---
title: Terraform Deposed
date: 2019-03-05
tags: terraform deposed
---

Нежданно-негаданно наткнулся сегодня на одно из возможных состояний ресурса, которое до сих пор [недокументированно](https://github.com/hashicorp/terraform/issues/10753). Когда выставляется в [жизненном цикле](https://www.terraform.io/docs/configuration/resources.html#lifecycle-lifecycle-customizations) ресурса директива `create_before_destroy`, то как следует их названия прежде чем удалить старый ресурс, сначала создается новый.

```HCL
resource "aws_instance" "example" {
  # ...

  lifecycle {
    create_before_destroy = true
  }
}
```

Что я не осозновал ранее, так это тот факт, что Terraform помечает старый ресурс как `deposed`. Такого рода ресурсы исключаются из интерполяции и просто удаляются в конце применения изменений. Вот как приблизительно выглядит вывод при изменении упомянутого ресурса:

```
Plan: 1 to add, 0 to change, 1 to destroy.

module.instance.aws_instance.example: Creating...
module.instance.aws_instance.example: Still creating... (10s elapsed)
module.instance.aws_instance.example: Still creating... (20s elapsed)
module.instance.aws_instance.example: Provisioning with 'remote-exec'...
module.instance.aws_instance.example: Creation complete after 57s (ID: i-0b4a7876b0ff9d10e)

module.instance.aws_instance.example.deposed: Destroying... (ID: i-04d414b59bb1f7c59)
module.instance.aws_instance.example (deposed #0): Still destroying... (ID: i-04d414b59bb1f7c59, 10s elapsed)
module.instance.aws_instance.example (deposed #0): Still destroying... (ID: i-04d414b59bb1f7c59, 20s elapsed)
module.instance.aws_instance.example.deposed: Destruction complete after 1m22s

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

Для такого рода ресурсов есть отдельная секция в файле описания состояния:

```JSON
...
"aws_instance.instance": {
  "type": "aws_instance",
  "depends_on": [],
  "primary": { ... },
  "deposed": [],
  "provider": "provider.aws"
},
...
```

В нормальных условиях секция `deposed` должна быть пустой. Если во время работы `terraform apply` возникли какие-то ошибки, то `deposed` ресурс останется записанным в state до следующего запуска. Таким образом Terraform не забудет таки подчистить за нами, когда ошибка будет исправлена.
