---
title: Маленький вопрос о больших (?) размерах Docker образов
date: 2017-11-20
tags: docker image
---

Имея представление о слоевой файловой системе ([OverlayFS](https://en.wikipedia.org/wiki/OverlayFS) по умолчанию на текущий момент) в Docker, я ни разу не убеждался практически в том, как измененяется размер образа в зависимости от определенных команд внутри Dockerfile. Давайте рассмотрим один из примеров того, почему образы могут быть больше, чем мы ожидаем.

```Dockerfile
FROM alpine               # 3.97 Mb

COPY north.m4a /north.m4a # 4.57 Mb – file mod 644

RUN chmod 400 north.m4a   # ? Mb

RUN rm north.m4a          # ? Mb
```

**Вопрос**

Нам известно, что базовый образ `alpine` занимает скажем 3.97 Мб, а файл `north.m4a` занимает 4.57 Мб. Сколько будет занимать финальный образ после выполнения всех команд внутри `Dockerfile`?

**Ответ**

{% raw %}
```
$ docker build -t probe .
$ docker images --format "{{.Size}}" probe
13.1MB # 3.97 + 4.57 + 4.57
```
{% endraw %}

Почему присутствует задвоение размера файла `north.m4a`? Фактически это вопрос о [понимани слоев в Docker образах](https://docs.docker.com/engine/userguide/storagedriver/imagesandcontainers). Если запустить команду `docker history`, то можно увидить, что изменение атрибутов файла добавленного в слое 2 (`COPY`) влечет за собой полное копирование этого файла в слой 3 (`RUN chmod`) с обновленными атрибутами. Последний же слой (`RUN rm`) хоть и удаляет файл из файловой системы, но никак не влияет на историю.

{% raw %}
```
$ docker history --format "table {{.ID}}\t{{.CreatedBy}}\t{{.Size}}" probe
IMAGE               CREATED BY                                      SIZE
da06ea73a176        /bin/sh -c rm /north.m4a                        0B
51dbdbfc96af        /bin/sh -c chmod 400 /north.m4a                 4.57MB
cb2341afb9e2        /bin/sh -c #(nop) COPY file:ad3c5aa1deab1b...   4.57MB
053cde6e8953        /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B
<missing>           /bin/sh -c #(nop) ADD file:1e87ff33d1b6765...   3.97MB
```
{% endraw %}

![Jekyll]({{ "/assets/docker-image-layers.svg" | absolute_url }})
