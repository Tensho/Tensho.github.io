---
title: git checkout -
date: 2017-12-20
tags: git
---

Недавно открыл для себя заново `git checkout -`, который работает аналогично `cd -` и подставляет последний использованый параметер. Это позволяет быстро переключатся между ветками (или и папками в случае `cd`).

```
$ git checkout master
Switched to branch 'master'
$ git checkout feature
Switched to branch 'feature'
$ git checkout -
Switched to branch 'master'
```
