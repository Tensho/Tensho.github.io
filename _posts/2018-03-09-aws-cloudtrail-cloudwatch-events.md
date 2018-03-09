---
title: Ньюансы AWS CloudTrail Events и CloudWatch Events
date: 2018-03-09
tags: aws cloudtrail cloudwatch events
---

Возможно кому-то это сразу показалось очевидным, но я только спустя некоторое время осознал (после вдумчивого изучения документации), что у **CloudTrail Events** и **CloudWatch Events** разные назначения и смысл. Однажды у меня возникло желание получать уведомления об использовании AWS API в Slack, т.к. это позволяет быть в курсе изменений в инфраструктуре, пока она вся не представлена в виде кода (infrastructure as as code). Со своей развесистой платформой интеграций Slack прекрасен для [ChatOps](https://en.wikipedia.org/wiki/ChatOps) и мониторинга как никто другой, чего уж там скромничать.

CloudTrail записывает любые обращения к AWS API (через AWS Web UI, AWS CLI, AWS API HTTP вызовы) и оформляет их в CloudTrail Events ведя историю таких событий (**Events History**) в рамках окна 90 дней. Среди прочего из записи о событии можно узнать кто, когда и что изменил в облаке. Операции чтения (Get, List, Describe) не поддерживаются CloudTrail. Если для аудита требуется хранить более 90 дней историю обращений к AWS, то нужно включать логирование (`Logging: ON`) в виде JSON файлов, которые CloudTrail любовно положит в S3 bucket. Генерируются такие файлы приблизительно каждые 5 минут. То, что меня запутало с первого раза, это опция относящаяся к SNS, которая просто шлет уведомление об очередном успешно созраненном лог файле в S3. Изначально мне казалось, что SNS как раз та дырка, через которую шлются все нужные мне события. [Например, один чувак слал Beanstalk нотификации через SNS в Lambda](https://medium.com/cohealo-engineering/how-set-up-a-slack-channel-to-be-an-aws-sns-subscriber-63b4d57ad3ea). Однако, для CloudTrail все выглядит по-другому. Для уведомлений в Slack целесообразно использовать Lambda. Но для обработки CloudTrail Events в Lambda, нужно сперва их сконвертировать в CloudWatch Events, т.к. только CloudWatch может выступать триггером функции Lambda. Для наглядности ниже представлена прототип функции для NodeJS:
 
 ```
var https = require('https');
var util = require('util');

exports.handler = function(event, context) {
    event_json = JSON.stringify(event, null, 2); 
    console.log(event_json);

    var postData = {
        "channel": "#aws",
        "username": "AWS CloudWatch",
        "icon_emoji": ":aws:"
    };
   
    postData.attachments = [
        {
            "color": "warning", 
            "title": "CloudWatch Event",
            "text": event_json
        }
    ];

    var options = {
        method: 'POST',
        hostname: 'hooks.slack.com',
        port: 443,
        path: 'https://hooks.slack.com/services/XXXXXXXXX/YYYYYYYYY/ZZZZZZZZZZZZZZZZZZZZZZZZ'
    };

    var req = https.request(options, function(res) {
      res.setEncoding('utf8');
      res.on('data', function (chunk) {
        context.done(null);
      });
    });
    
    req.on('error', function(e) {
      console.log('problem with request: ' + e.message);
    });    

    req.write(util.format("%j", postData));
    req.end();
};
 ```
 
И оказывается CloudtTrail автоматически посылает свои события в CloudWatch Events Stream! Не нужно никаких дополнительных телодвижений для преобразования событий из одного формата в другой.

 ![AWS CloudTrail Events & CloudWatch Events]({{ "/assets/aws-cloudtrail-cloudwatch-events.svg" | absolute_url }})

Ньюанс заключается в том, что CloudWatch Events делятся на 2 типа:

 1. Генеруемые самими AWS ресурсами при смене их состояния (EC2 инстанс прешел из состояния starting в running)
 2. Те самые CloudTrail события, которые фиксируют API вызовы (EC2 инстанс был terminated польователем tensho)
 
 Важно понимать, что событий 1 типа фиксируют создание, изменение и удаление ресурсов **извне** кем-либо (включая сами AWS сервисы), а события 2 типа уведомляют о состоянии работы уже существующих ресурсов **изнутри** самим AWS (CloudWatch).
 
 После того, как это все это становится понятным, остается лишь настроить CloudWatch Event Rule для того, чтобы только интересующие события триггерили заранее подготовленную Lambda функцию. 
 
 Кстати все это время я имел в виду CloudTrail Management Events, т.к. в CloudTrail есть еще Data Events (отключены по умолчанию). Фактически первые рассказывают об изменении в состоянии AWS ресурсов, а вторые – о данных обрабатываемых ресурсами. Например, создание S3 бакета отражается событием управления, а запись или чтение объекта из S3 бакета – событием обращения к данным. На текущий момент только S3 и Lambda генерируют Data Events.
 
 AWS старается расширять список событий обоих типов событий.
  
 - [CloudTrail Event формат](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference.html)
 - [CloudWatch Event формат](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html)
 
К сожалению, CloudWatch Rule позволяет трансформировать входящее событие, но не позволяет выбрать целью Slack endpoint (отослать HTTP запрос без посредника), иначе можно было бы сократить расходы на Lambda.
