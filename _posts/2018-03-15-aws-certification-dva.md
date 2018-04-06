---
title: Моя AWS DVA сертификация
date: 2018-03-15
tags: aws certification solution architect associate
---

В AWS предлагают сертифицироваться по нескольким направлениям работы с облаком:

![AWS Certification Roadmap]({{ "/assets/aws-cert-roadmap.png" | absolute_url }})

Совсем недавно я сдал **AWS Developer – Associate (DVA)** и планирую также сдавать **AWS Solutions Architect - Associate (SAA)** в ближайшем будущем. На мой субъективный взгляд наиболее полезной специализацией является Solution Architect, даже если вы ежедневно работает с AWS как Software Engineer или System Engineer. В конце концов хороший инженер должен понимать, как устроены инструменты и почему используется тот или иной в зависимости от поставленной задачи. Прочитать документацию по внедрению и запрограммировать уже осознанно выработанное решение обычно не состовляет проблем.

На Developer экзамене большинство вопросов касались:

- **DynamoDB**. [Capacity Units (CU)](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ProvisionedThroughput.html), [Burst Capacity](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GuidelinesForTables.html#GuidelinesForTables.Bursting), [Scan](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html), [Indexes](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/SecondaryIndexes.html)
- **S3**. [CORS](https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html), [Server-Side Encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html), [Pre-Signed URL](https://docs.aws.amazon.com/AmazonS3/latest/dev/PresignedUrlUploadObject.html), оптимальное именование иерархии объектов, хранение архивных данных
- **SNS**. [Subscriber](https://docs.aws.amazon.com/sns/latest/dg/welcome.html), [Message Attributes](https://docs.aws.amazon.com/sns/latest/dg/SNSMessageAttributes.html)
- **SQS** [Long Polling](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html)

Было по парочке вопросов о Beanstalk, CloudFormation, Lambda, EC2 + AMI. 

Мне показалось странным, что было немало вопросов на знание точного названия какого-нибудь метода AWS CLI (get EC2 AMIs in region – describeImages) или определенного лимита для ресурса (minimum SQS Message Retention – 1 minutes). Конечно при ежедневной работе с AWS повторяющиеся слова врезают в память, но все же оценивать знания справочной информации на экзамене кажется неправильным. 

### Агенда экзамена

- Дата: 1 марта
- Цена: 150$
- Время: 80 минут
- Количество вопросов: 55

### Cписок ресурсов
 
 - Курс [A Cloud Guru "Certified Solutions Architect - Associate 2018"](https://acloud.guru/learn/aws-certified-solutions-architect-associate) за авторством Раяна Круненберга
 - Книга ["AWS Certified Solutions Architect Official Study Guide: Associate Exam"](https://www.goodreads.com/book/show/32611599-aws-certified-solutions-architect-official-study-guide)
 - Whitepapers
   - [AWS Pricing](http://d0.awsstatic.com/whitepapers/aws_pricing_overview.pdf)
   - [AWS Well Architected Framework](https://d1.awsstatic.com/whitepapers/architecture/AWS_Well-Architected_Framework.pdf)
 - Видео
   - [AWS re:Invent 2015: DevOps at Amazon: A Look at Our Tools and Processes (DVO202)](https://www.youtube.com/watch?v=esEFaY0FDKc)
  
Ну и конечно сложно переоценить практический опыт работы с AWS в рамках работы над проектом.

### Результат

[Certificate](https://www.certmetrics.com/amazon/public/badge.aspx?i=2&t=c&d=2018-03-01&ci=AWS00435488)

### Интересные моменты

Из-за погодных условий я на 30 минут опоздал на экзамен в офис компании [Smart Business](https://www.google.com.ua/maps/place/SMART+business/@50.4449035,30.4509081,21z/data=!4m5!3m4!1s0x40d4cdb68dfea8d3:0x8d42eb286c790b6b!8m2!3d50.4441317!4d30.4528705), но мне разрешили его начать по прибытию с полным контролем времени, предварительно получив разрешения от AWS и Certmetrics. Так что там тоже люди работают ^_^

