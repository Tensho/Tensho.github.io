---
title: Образ диска хоста Docker for Mac
date: 2018-01-17
tags: docker vm disk image
---

В [Docker for Mac 17.12.0-ce-mac46](https://docs.docker.com/docker-for-mac/release-notes/#docker-community-edition-17120-ce-mac47-2018-01-12-stable) таки кое-что сделали, чтобы производительность работы Docker на базе стандартной файловой системы **APFS** в **macOS High Sierra** была лучше. Ранее при рассмотрении [OSXFS]({% post_url 2017-11-26-docker-for-mac-file-system %}) я писал о проблемах возникающих при монтировании больших томов и как эти проблемы решаются на разных уровнях (параметры монтирования или [docker-sync]({% post_url 2017-12-10-docker-sync %})). Теперь разработчики Docker предлагают перейти от формата хранения дискового образа (disk image) Docker хоста **[qcow2](https://ru.wikipedia.org/wiki/Qcow2)** к **raw** (сырому). Qcow2 (QEMU Copy-On-Write) образ диска удобен для использования маленьких образов в формате файловых систем не поддерживаемых операционной системой. Docker хранит всю информацию об образах и контейнерах в отдельном образе дикска, который монтируется внутрь VM. После обновления и удаления всех старых образов и контейнеров Docker автоматически начнет использовать raw формат. Данное изменение предполагает, что производительность работы с диском будет увеличена практически в 2 раза. Сам образ хранится по следующему пути `~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux` и называется `Docker.raw` вместо `Docker.qcow2`. Этот же путь и размер файла образа диска можно увидеть в настройках Docker.app:

![Docker.app Preferences Disk QCow2]({{ "/assets/docker-app-preferences-disk-before.png" | absolute_url }})
![Docker.app Preferences Disk Raw]({{ "/assets/docker-app-preferences-disk-after.png" | absolute_url }})

Есть еще один интересный момент, оказывается APFS поддерживает разреженныек файлы (sparse files), которые сжимают подряд идущие нули представляющие неиспользуемое место. Забавно то, что можно попасть в замешательство глядя на размер raw файла с помощью утилиты `ls`, т.к. в таком виде она показывает исключительно логический размер. Что посмотреть физический размер нужно прибегнуть к утилите `du` (disk usage):

    $ ls -lh ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/Docker.raw | awk '{print $5, $9}'
    64G /Users/tensho/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/Docker.raw

    $ du -h ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/Docker.raw
    3.2G   /Users/tensho/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/Docker.raw

Те, кто не спешит обновляться, должны знать, что со временем `Docker.qcow2` файл разрастается хоть Docker приодически предпринимает попытки его затримить с помощью **fstrim** в рамках cron задачи.

