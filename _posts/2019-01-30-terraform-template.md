---
title: Terraform Template
date: 2019-01-30
tags: terraform template
---

Небольшая заметка про шаблоны в [Terraform](https://www.terraform.io). До `terraform 0.12` шаблоны обрабатываются отдельным [провайдером](https://www.terraform.io/docs/providers/index.html) `terraform-provider-template`, который идет в качестве плагина из коробки. В будущем обработку шаблонов планируют сделать на базе `templatefile` [встроенной функции](https://www.terraform.io/docs/configuration/interpolation.html#built-in-functions). Итак давайте создадим пару файлов – описание конфигурации

```HCL
data "template_file" "alpha" {
  template = "${file("alpha.tpl")}"
  vars = {
    x = "X"
    y = "Y"
  }
}
```

и непосредственно шаблон

```HCL
${x} and ${y}
```

Можно передать переменные через аргумент `vars`, на которые потом сослаться в шаблоне посредством [стандартного синтаксиса интерполяции](https://www.terraform.io/docs/configuration/interpolation.html).

Важно то, что интерполяция не будет выполнена до тех пор, пока не пройдет применение конфигурации с помощью `terraform apply` и не обновится [состояние инфраструктуры](https://www.terraform.io/docs/state/index.html).

```
$ terraform init
$ terraform apply
data.template_file.alpha: Refreshing state...

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
$ terraform console
> data.template_file.alpha.rendered
X and Y
> exit
```
Свойство [`rendered`](https://www.terraform.io/docs/providers/template/d/file.html#rendered) ресурса данных [`template_file`](https://www.terraform.io/docs/providers/template/d/file.html) как раз позволяет взять финальный результат рендеринга в виде строки.

А еще удобно эксперементировать однострочниками в таком виде:

```
$ echo data.template_file.alpha.rendered | terraform console
X and Y
```
