---
title: MacOS Time Machine Utility
date: 2019-07-29
tags: macos time machine console terminal utility tmutil
---

Проверяя в очередной раз настройки бекапирования моего MacBook Pro (MBP), я наткнулся на консольную утилиту `tmutil`. Хотя графический интерфейс Time Machine (TM) сам по себе лаконичен и понятен, управлять настройками TM из терминала все же приятней. Потенциально такая штука может понадобится для автоматизации развертывания новой системы. Детали можно найти на соответствующей `man` странице, здесь же я хочу отметить несколько команд для затравки. Рассмотрим пример удаления и повторного создания резервной копии MBP.

```
$ tmutil destinationinfo
====================================================
Name          : Tensho
Kind          : Network
URL           : afp://Tensho;AUTH=SRP@Tensho%20AirPort%20Time%20Capsule._afpovertcp._tcp.local./Tensho
Mount Point   : /Volumes/Tensho
ID            : D397B0D6-2714-47D1-9860-4B7616EC61CC
```
```
$ sudo tmutil disable
``` 
```
$ sudo tmutil removedestination D397B0D6-2714-47D1-9860-4B7616EC61CC
```
```
$ tmutil destinationinfo
tmutil: No destinations configured.
```
```
$ sudo tmutil setdestination -p afp://Tensho@Tensho%20AirPort%20Time%20Capsule._afpovertcp._tcp.local/Tensho
Destination password:
```
```
$ sudo tmutil addexclusion ~/Downloads
```
```
$ sudo tmutil enable
```
``` 
$ sudo tmutil startbackup --auto
```
```
$ tmutil machinedirectory
/Volumes/Time Machine Backups/Backups.backupdb/Tensho MBP
```
```
$ tmutil listbackups
/Volumes/Time Machine Backups/Backups.backupdb/Tensho MBP/2019-07-29-010618
/Volumes/Time Machine Backups/Backups.backupdb/Tensho MBP/2019-07-29-021211
/Volumes/Time Machine Backups/Backups.backupdb/Tensho MBP/2019-07-29-100231
```
```
$ tmutil latestbackup
/Volumes/Time Machine Backups/Backups.backupdb/Tensho MBP/2019-07-29-100231
```
```
$ tmutil listlocalsnapshots /
com.apple.TimeMachine.2019-07-28-162831
com.apple.TimeMachine.2019-07-29-015308
com.apple.TimeMachine.2019-07-29-094335
```
``` 
$ sudo tmutil calculatedrift /Volumes/Time\ Machine\ Backups/Backups.backupdb/Tensho\ MBP

2019-07-29-010618 - 2019-07-29-021211
-------------------------------------
Added:         152.2M
Removed:       80.0M
Changed:       446.0M


2019-07-29-021211 - 2019-07-29-100231
-------------------------------------
Added:         90.2M
Removed:       96.4M
Changed:       140.7M


Drift Averages
-------------------------------------
Added:         80.8M
Removed:       58.8M
Changed:       195.6M
```

Вне досягаемости сетевого диска TM складирует изменения на локальном диске до тех пор, пока не появится соедиение с внешним хранилищем. Такие копии занимают достаточно много пространства, поэтому для ~~бомжей с малым размером диска~~ бережливых хозяек есть отдельные команды управления этим поведением – `tmutil disablelocal`/`tmutil enablelocal`.
