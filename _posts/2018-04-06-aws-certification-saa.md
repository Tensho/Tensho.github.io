---
title: Моя AWS SAA сертификация
date: 2018-04-06
tags: aws certification solutions architect associate
---

Совсем недавно [я сдал AWS Developer – Associate (DVA)]({% post_url 2018-03-15-aws-certification-dva %}) и вот теперь подошел черед **AWS Solutions Architect - Associate (SAA)**. Сразу хочу отметить, что c 12 августа экзамен новый (2018) и включает в себя ряд тем, которые не поднимались в SAA более ранней версии – API Gateway, Lambda, EFS. Т.к. я готовилися по материалам для более ранней версии, то не преминул ознакомиться с нововведениями предварительно. В целом экзамен мне показался правильным, в смысле вопросы были действительно направлены на выработку какого-то решения по конкретному запросу от бизнеса или разработчиков. Было много вопросов, на которые предлагались корректные альтернативные решения в ответах, но надо было внимательно выбирать тот, который лучше других подходит под заданный критерий – минимальная стоимость, максимальная производительность, максимальная отказоустойчивость, высокая досутпность, наибольшая безопасность, оптимальный баланс нескольких свойств. В вопросе требуемый КРИТЕРИЙ выписывается сециально большими буквами.

![AWS Certification Roadmap]({{ "/assets/aws-cert-roadmap.png" | absolute_url }})

На Solutions Architect (SA) экзамене большинство вопросов касались:

- **VPC**. [Peering](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-peering.html), [Endpoints](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-endpoints.html), [Public/Private Subnets](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html), [NAT Gateways](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-nat-gateway.html), [ACL](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_ACLs.html), [Security Groups](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_SecurityGroups.html)
- **Route53**. [Routing policy](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html)
- **DynamoDB**. [Capacity Units (CU)](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ProvisionedThroughput.html), [Burst Capacity](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GuidelinesForTables.html#GuidelinesForTables.Bursting), [Indexes](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/SecondaryIndexes.html)
- **S3**. [Server-Side Encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html), [Pre-Signed URL](https://docs.aws.amazon.com/AmazonS3/latest/dev/PresignedUrlUploadObject.html), [Versioning](https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html), [Glacier](https://docs.aws.amazon.com/amazonglacier/latest/dev/introduction.html), [Transfer Acceleration](https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html), оптимальное именование иерархии объектов
- **EBS**. [Volume Types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumeTypes.html), [Encryption](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html)
- **EFS**. [Overview](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html)
- **SNS**. [Overview](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)
- **SQS**. [Overview](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html)
- **API Gateway** [Overview](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html)
- **Lambda**. [Environment variables](https://docs.aws.amazon.com/lambda/latest/dg/env_variables.html)
- **CloudWatch**. [Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html?shortFooter=true#Metric), [Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html?shortFooter=true#CloudWatchAlarms)
- **RDS**. [Multi-AZ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html), [Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Aurora.html?shortFooter=true), [Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- **IAM**. [Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html), [Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html?shortFooter=true)
- **Redshift**. [Snapshots](https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html), [Encryption](https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-db-encryption.html)
- **Kinesis Firehose**. [Overview](https://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html)

Понятное дело, что в доль и поперек присутствовали EC2 и Load Balancers (ELB/ALB/NLB). Рассматривались 1-tire (static), 2-tires (dynamic + database) и 3-tires (static + dynamic + database) архитектуры. Был вопрос о том, как оптимизировать стоимость инфраструктуры за счет перехода с Route53 + ELB + EC2 на API Gateway + Lambda.

### Агенда экзамена

- Дата: 2 апреля
- Цена: 150$
- Время: 130 минут
- Количество вопросов: 65

### Cписок ресурсов
 
 - Курс [A Cloud Guru "Certified Solutions Architect - Associate 2018"](https://acloud.guru/learn/aws-certified-solutions-architect-associate) за авторством Раяна Круненберга
 - Книга ["AWS Certified Solutions Architect Official Study Guide: Associate Exam"](https://www.goodreads.com/book/show/32611599-aws-certified-solutions-architect-official-study-guide)
 - Whitepapers
   - [AWS Pricing](http://d0.awsstatic.com/whitepapers/aws_pricing_overview.pdf)
   - [AWS Well Architected Framework](https://d1.awsstatic.com/whitepapers/architecture/AWS_Well-Architected_Framework.pdf)
 - Видео
   - [AWS re:Invent 2015: DevOps at Amazon: A Look at Our Tools and Processes (DVO202)](https://www.youtube.com/watch?v=esEFaY0FDKc)
  
А также практика, практика, практика.

### Результат

[Certificate](https://www.certmetrics.com/amazon/public/badge.aspx?i=1&t=c&d=2018-04-02&ci=AWS00435488)

### Интересные моменты

На этот раз я указал время экзамена на середину дня и приехал в офис компании [Smart Business](https://www.google.com.ua/maps/place/SMART+business/@50.4449035,30.4509081,21z/data=!4m5!3m4!1s0x40d4cdb68dfea8d3:0x8d42eb286c790b6b!8m2!3d50.4441317!4d30.4528705) за 1.5 часа до начала, при этом мне разрешили начать проходить экзамен за пол часа до назначенного времени.

