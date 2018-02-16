---
title: Долгоживущее соединение RabbitMQ и AWS ELB 
date: 2017-12-05
tags: aws elb rabbitmq idle connection
---

В один прекрасный день я заметил в логах веб приложения, что Ruby клиент RabbitMQ [bunny](http://rubybunny.info) начал периодически логировать исключения вида:

```
E, [2017-12-01T16:19:23.527226 #1] ERROR -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: Exception in the reader loop: AMQ::Protocol::EmptyResponseError: Empty response received from the server.
E, [2017-12-01T16:19:23.527300 #1] ERROR -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: Backtrace:
E, [2017-12-01T16:19:23.527337 #1] ERROR -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: /usr/local/bundle/gems/amq-protocol-2.2.0/lib/amq/protocol/frame.rb:60:in `decode_header'
E, [2017-12-01T16:19:23.527357 #1] ERROR -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: /usr/local/bundle/gems/bunny-2.7.1/lib/bunny/transport.rb:245:in `read_next_frame'
E, [2017-12-01T16:19:23.527369 #1] ERROR -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: /usr/local/bundle/gems/bunny-2.7.1/lib/bunny/reader_loop.rb:68:in `run_once'
E, [2017-12-01T16:19:23.527380 #1] ERROR -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: /usr/local/bundle/gems/bunny-2.7.1/lib/bunny/reader_loop.rb:35:in `block in run_loop'
E, [2017-12-01T16:19:23.527389 #1] ERROR -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: /usr/local/bundle/gems/bunny-2.7.1/lib/bunny/reader_loop.rb:32:in `loop'
E, [2017-12-01T16:19:23.527399 #1] ERROR -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: /usr/local/bundle/gems/bunny-2.7.1/lib/bunny/reader_loop.rb:32:in `run_loop'
W, [2017-12-01T16:19:23.527416 #1] WARN -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: Will recover from a network failure (no retry limit)...
W, [2017-12-01T16:19:33.528006 #1] WARN -- #<Bunny::Session:0x5b55900 app@message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672, vhost=production, addresses=[message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672]>: Retrying connection on next host in line: internal-message-broker-internal-823843780.eu-west-1.elb.amazonaws.com:5672
```

Меня это насторожило и я решил проверить не теряем ли мы какие-либо сообщения при отправке, т.к. расширение [RabbitMQ Publisher Confirms](https://www.rabbitmq.com/confirms.html#publisher-confirms) не было еще включено. Я написал простенький скрипт, который отправлял запросы каждую секунду, запустил и с ужасом обнаружил, что во время обрыва соединения пакеты таки теряются! После недолгих рисований диаграм, размышлений и разговоров с коллегами, я пришел к выводу, что проблема лежит в AWS ELB, который закрывал RabbitMQ EC2 инстанс. Оказывается, балансировщик не расчитан на поддержку долгоживущих соединений и по умолчанию обрубает неактивные (Idle) соединения более **60 секунд**. Т.к. по умолчанию значение сердцебиения (heartbeat) RabbitMQ клинета принимала от сервера и равно было тоже **60 секундам**, то клиент практически всегда не успевал сообщить серверу, что он еще живой. Следовательно балансировщик обрубал неактивное соединение. Поэтому важно выставлять правильные значения, чтобы интервал сердцебинения был строго меньше интервала AWS ELB Idle Timeout, лучше даже с запасом. Например: `RabbitQM Heartbeat = Idle Timeout / 2`.

![Jekyll]({{ "/assets/aws-elb-rmq.svg" | absolute_url }})

- http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html
- https://www.rabbitmq.com/heartbeats.html#tcp-proxies

Позже я нашел тред ["Rabbitmq and AWS ELB"](https://groups.google.com/forum/#!topic/rabbitmq-users/lzRnjNyNppk) в Google гуппах, который подтверждал мои догадки.

Есть еще мысль о том, чтобы перевести балансировку на уровень DNS, прикрепив к RabbitMQ EC2 инстансу Elastic IP и домен сверху, что выглядит более правильным решением проблемы персистентного адреса сервиса, т.к. фактически балансировать нагрузку между разными нодами RabbitMQ кластера мне пока совсем не надо.

Что нужно сделать дополнительно, так это добавить Publisher Confirms, чтобы любые неполадки сети (в том числе и по собственной вине неправльной конфигурации) не мешали быть уверенным в гарантиях публикации сообщений. 
