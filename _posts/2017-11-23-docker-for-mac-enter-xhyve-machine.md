---
title: Вход в виртуальную машину Docker for Mac
date: 2017-11-23
tags: docker vm xhyve
---

Чтобы попасть внуть виртуальной машины, которую запускает **Docker for Mac** на базе [MacOS Hypervisor Framework](https://developer.apple.com/documentation/hypervisor) под капотом, нужно передать любезно подготовленный терминал в качестве параметра `screen` утилите:

```
screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty
```

Находясь внутри можно, например, убедиться, что разделяемая файловая система [osxfs](https://docs.docker.com/docker-for-mac/osxfs/) используется по умолчанию только для определенных папок из MacOS корня:

```
/ # df -a | grep osxfs
osxfs                118284248  89517540  22872412  80% /private
osxfs                118284248  89517540  22872412  80% /tmp
osxfs                118284248  89517540  22872412  80% /Volumes
osxfs                118284248  89517540  22872412  80% /Users
``` 

Для выхода из screen сессии нужно нажать комбинацию [`Ctrl + a Ctrl + \`](https://www.gnu.org/software/screen/manual/html_node/Quit.html#Quit).
