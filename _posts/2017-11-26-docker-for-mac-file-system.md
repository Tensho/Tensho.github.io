---
title: Файловая система Docker for Mac
date: 2017-11-26
tags: docker filesystem osxfs
---

Данный пост представляет собой вольный тезисный перевод статей о **osxfs**.

- https://docs.docker.com/docker-for-mac/osxfs
- https://docs.docker.com/docker-for-mac/osxfs-caching

### Регистрозависимость (Case sensitivity)

Файловая система **HFS+** по умолчанию сase-insensitivity, поэтому если внутри контейнера будет файловая система сase-sensitivite – пиши пропало, т.к. это критично для точек монтирования (bound mounts). При этом с томами (volumes) должно быть все в порядке, насколько я понял.

### Владение (Ownership)

Внутри контейнера все объекты принадлежат текущему пользователю. Если мы делаем chown, то изменение владельца файла записывается в расширенные атрибуты (extended attributes) под ключем `com.docker.owner`. Если пользователю внутри контейнера отказано в доступе к расширенным атрибутам, то `osxfs` попытается добавить ему эти права через ACL.

### События файловой системы (File System Events)

Большинство (не все) `inotify` событий файловой системы macOS поддерживаются и пробрасываются внутрь контейнера, следовательно подписанный на них процесс может успешно реагировать.

### Монтирование (Mounts)

Лучше не монтровать тома в файловую систему macOS, которые прибиндены (bind mount) внутрь контейнера.

### Символические ссылки (Symlinks)

Все те же грабли с регистрозависимостью, см. выше.

### Типы файлов (File Types)

Поддерживаются символически ссылки, жесткие ссылки, сокет файлы, именованные каналы, обыкновенные файлы и директории. Сокет файлы и именованные каналы передают данные между контейнером и хостом (macOS), но не между гипервизорами. Файлы символьных и блочных устройств не поддерживаются.

### Расширенные атрибуты (Extended Attributes)

Не поддерживаются.

### Производительность

Производительность файловой системы зависит в основном от пропускной способоности чтения/записи (объем данных) и задержки раундтрипа (время на выполнение вызова файловой системы). Как видно ниже из сравнительной таблицы рядовой файловой системы и `osxfs`, последняя уступает в разы:

| Метрика                        | Рядовая ФС  | osxfs    |
| ------------------------------ | ----------- | -------- |
| Пропускная способность для SSD | 2.5 Гб/с    | 2.5 Мб/s |
| Задежрка                       | 10 мкс      | 130 мкс  |

#### Что можно делать для улучшения ситуации?

1. **Кешировать данные**. В Docker 17.04 добавили кеширование, что дало 2-4x прирост производительности. Минусом данного подхода является послабление гарантий консистентности данных между хостом и контейнером, но видимо с этим можно считаться. Есть еще целое поле для пахоты в этом направлении, например применение negative cache.

2. Пропатчить Linux на предмет сокращения раундтрипа.

3. Улучшить интеграцию с macOS, чтобы уменьшить задержку между гипервизором и сервером файловой системы.

### Что предлаегает Docker 17.04?

Жертвовать консистентностью файловой системы в угоду производительности. Предолжены следующие конфигурационные параметры при монтировании:

- `consistent` (`default`) – идеальная консистентность (хост и контейнер имеют идентичный вид смонтированной области).

- `cached` - хост авторитетней (разрешаются задержки перед тем, как обновления на хосте будут видны в контейнере). Компромис консистентности – записи в контейнере видны мнгновенно на хосте, но записи на хосте видны в контейнере не сразу. Этот режим подходит для приложений, в которых много читают, но не пищут.

- `delegated` - контейнер авторитетней (разрешаются задержки перед тем, как обновления в контейнере будут видны на хосте). Минимальный уровень консистентности – если область монтирования (bind mount) свалится с незасинхронизированными записями на диск, то они будут потеряны.

На рисунке изображена попытка скудного осознания темы:

![Jekyll]({{ "/assets/docker-for-mac-osxfs.svg" | absolute_url }})

Я планирую время от времени поглядывать вглубь osxfs насколько это будет мне по силам, чтобы сделать диаграмму более понятной и наглядной. К сожалению в сети не так уж и много годных статей о специфике работы Docker for Mac. Разве что нужно шерстить тонны релевантных GitHub Issues. Есть еще проект [docker-sync](https://github.com/EugenMayer/docker-sync) с неплохой документацией, которую я хотел бы почитать внимательно. Цель **docker-sync** кардинально решить проблемы с производительностью **osxfs**.
