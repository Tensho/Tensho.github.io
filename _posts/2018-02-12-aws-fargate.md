---
title: AWS Fargate
date: 2018-02-12
tags: aws fargate ecs
---

В прошлом году я начал использовать [AWS ECS](https://aws.amazon.com/ecs) как основное средство развертывания Docker контейнеров в облаке. Основной площадкой для запуска Docker хостов как можно догадаться является EC2. ECS представляет собой распределенное key/value хранилище (транзакционное журналируемое распределенное основанное на PAXOS) хранящее информацию о всех кластерах и являющееся единственным достоверным источником правды о текущем состоянии ваших кластеров. На каждом ECS инстансе запущен ECS агент (написанный на Go), который регулярно синхронизирует информацию о текущей машине с менеджером кластера. По умолчанию все машины находятся в AutoScaling Group (вероятно в разных AZ) для обеспечения эластичности кластера. После настройки кластера пользователю выдаются абстракции сервиса (Service) и задачи (Task). Фактически задачи – это и есть контейнеры, параметры и связи между которыми описываются в специальных определениях (Task Definition). Сервисы же представляют входную точку в контейнейры посредством балансировщика (Application Load Balancer) и следят за их жизненным циклом. Т.е. если один из контейнеров сдох, то сервис может его переподнять и такми образом поддерживать желаемое кол-во вычислительных мощностей. В ECS я плачу за время использования инстансов, пока запускаю на них контейнеры, а также за входящий/исходящий трафик. Так вот ребята из AWS запустили новый вид абстракции над вычислительными мощностями по имени *Fargate*. По сути это переход от управления виртуальными машинами к управлению контейнерами (задачами).

Что нам предлагает тип запуска задач Fargate:

- Мы не паримся выбором подходящего типа инстанса под наш профиль нагрузки, а подбираем уже ресурсы под выполнение конкретной задачи в контейнере
- Все так же есть возможность рулить security groups, routing rules и ACLs в рамках *awsvpc* сетевого режима + выделение публичных IP
- Все так же есть возможность накидывать разрешения с помощью IAM, но видимо теперь это будет более сокращенный набор правил, т.к. часть забот о инфраструктуре ложится на плечи AWS
- Можно запускать гибридные кластеры с Fargate и EC2 типами задач

К сожалению Fargate в регионе Ireland (eu-west-1) еще не доступен, но уже сейчас можно подготавливать свои скрипты автоматизации для перехода на более комфортный тип запуска контейнеров в ECS или [EKS](https://aws.amazon.com/eks).
