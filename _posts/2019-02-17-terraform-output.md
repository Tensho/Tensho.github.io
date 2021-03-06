---
title: Terraform Output
date: 2019-02-17
tags: terraform output
---

Terraform позволяет вывести полезную информацию с помощью `output` директивы. Таким образом, после применения изменений к инфраструктуре, можно посмотреть, например, IP адрес замененного EC2 или URI новосозданного RDS инстанса.    Есть один интересный ньюанс работы с такого рода выхлопом в рамках Terraform модулей. Давайте рассмотрим следующий пример корневого модуля:
s
```HCL
output "a" {
  value = "A"
}

output "b" {
  value = "B"
}

module "x" {
  source = "x"
}
```

Здесь определены корневые (родительские) значения вывода `a` и `b`, а также затребован модуль `x`. Модуль `x` имеет свои выводы `c` и `d`:

```HCL
output "c" {
  value = "C"
}

output "d" {
  value = "D"
}
```

Чтобы увидеть выводы нужно сначала применить обновления к текущему состоянию (даже если фактически состояния нет – первый запуск):

```
$ terrafrom apply

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

a = A
b = B
```

Если нужно посмотреть выводы позже, то для этого есть отдельная команда CLI [`output`](https://learn.hashicorp.com/terraform/getting-started/outputs.html):

```
$ terraform output
a = A
b = B
```

Однако, где ожидаемые `c` и `d` из модуля `x`? Их нет! Точнее они есть, но не видны. Так задумано по дизайну Terraform – корневой модуль должен явно определять выводы модулей, т.к. модуль должен восприниматься чем-то инкапсулированным, скрывающим свои внутринности. Так как же все-таки увидеть желаемое? Во первых можно вспороть модуль через CLI опцию `-module`:

```
$ terraform output -module=x
c = C
d = D
```

Но конечно это подходит только для обособленной интроспекции модуля. Чтобы фактически использовать выводы модуля `x` в корневом модуле, нужно проксировать изолированный выводы модуля:

```HCL
output "a" {
  value = "A"
}

output "b" {
  value = "B"
}

module "x" {
  source = "x"
}

// Proxy output from module
output "c" {
  value = "${module.x.c}"
}

output "d" {
  value = "${module.x.d}"
}
```

Не забываем применить изменения к состоянию и смотрим что теперь все как надо:

```
$ terrafrom apply

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

a = A
b = B
c = C
d = D
```
