---
title: Docker Volume Mount
date: 2018-05-08
tags: docker volume mount
---

Обучение – процесс иттеративный. Каждый новый подход к материалу позволяет лучше его понять. Не нужно стесняться своих ошибок, нужно уметь их признавать и стараться их не повторять в будущем. В заметке [Docker Data Management]({% post_url 2018-02-21-docker-data-management %}) я описывал, что можно совместно использовать том с установленными в него гемами в нескольких Ruby контейнерах. Однако, я не учел тот факт, что **именованные тома перекрывают (затеняют) данные в контейнере**. В процессе сборки образа гемы установливаются в `/usr/local/bundle`, а позже при запуске контейнера они монтируются в именованный том `rubygems-2.4.1`. Если таким образом собирать разные Ruby проекты, то их наборы гемов будут перекрывать друг друга каждый раз, когда будут запускаться контейнеры с монтируемым томом. Следовательно для этой задачи нужно использовать точки монтирования (монтировать с хоста).

Давайте рассмотрим положение дел описанное выше на простых примерах. Создаем примитивный `Dockerfile` со следующим содержимым:

```Dockerfile
FROM alpine

WORKDIR /hole

RUN touch x.txt
```

Собираем образ с файлом `x.txt` внутри:

    $ docker build . -t docker-hole

Создаем именованный том:

    $ docker volume create shelf

Проверяем, что в пустой именованный том копируются данные из контейнера:

    $ docker run --rm -v shelf:/hole docker-hole ls /hole
    x.txt

Создаем `y.txt` внутри тома:

    $ docker run -rm -v shelf:/hole docker-hole touch /hole/y.txt

Проверяем, что именованный том перекрывает (затеняет) данные при монтировании: 

    $ docker run --rm -v shelf:/hole docker-hole ls /hole
    y.txt

Создаем папку для монтирования (не обязательно, т.к. Docker сам создаст несуществующую папку):

    $ mkdir hole

Проверяем, что точка монтирования (bind mount) в виде пустой папки перекрывает данные внутри контейнера:

    $ docker run --rm -v $PWD/hole:/hole docker-hole ls /hole


Добавляем файл `z.txt` на хосте:

    $ touch hole/z.txt

Проверяем, что точка монтирования (bind mount) в виде непустой папки перекрывает данные внутри контейнера:

    $ docker run --rm -v $PWD/hole:/hole docker-hole ls /hole
    z.txt

Ниже сведена таблица получившихся результатов:

| Image        | Named Volume | Result |
| -------------| ------------ | ------ |
| x.txt        |              | x.txt  |
| x.txt        | y.txt        | y.txt  |

| Image        | Host Volume  | Result |
| -------------| ------------ | ------ |
| x.txt        |              |        |
| x.txt        | z.txt        | z.txt  |