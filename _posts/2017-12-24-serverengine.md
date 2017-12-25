---
title: ServerEngine
tags: serverengine sneakers
---

В текущем проекте я использую [sneakers](https://github.com/jondot/sneakers) в качестве основного фреймворка обработки RabbitMQ сообщений. Коротко говоря, Sneakers создает набор подтребителей (consumers) сообщений посредством [bunny](https://github.com/ruby-amqp/bunny) (который является де-факто стандартным клиентом RabbitMQ в мире Ruby) с помощью декларативной конфигурации. Я наверняка расскажу, как устроен Bunny изнутри позже, а сейчас я бы хотел обратить внимание на другую важную зависимость Sneakers – фреймворк для построения мультипроцессных серверов [serverengine](https://github.com/treasure-data/serverengine). Фактически это такая приблуда, которая позволяет запускать демон-сервер в различных режимах – простой, многопроцессный, многопоточный. Из коробки доступны попутно логгирование, обработка сигналов, возможность изменять имя процесса, динамическая перезагрузка конфигурации.
 

 Sneakers использует режим многопроцессного сервера для управления, поэтому я бы и хотел поэксперементровать в первую очередь с этим режимом. Давайте прикинем функциональную схеу того, что бы хотелось получить:
 
 ![ServerEngine]({{ "/assets/serverengine.svg" | absolute_url }})
 
 А теперь напишем простой воркер и зададим необходимые опции для запуска сервера в многопроцессном режиме:
 
 ```ruby
# run.rb 
 
module SimpleWorker
  def run
    until @stop
      logger.info "[worker_id: #{worker_id}] Awesome work!"
      sleep 5
    end
  end
  
  def stop
    @stop = true
  end
end

 ServerEngine.create(nil, SimpleWorker, {
   daemonize: true,
   log: 'server.log',
   pid_path: 'server.pid',
   daemon_process_name: 'se-server',
   worker_process_name: "se-worker",
   worker_type: 'process',
   workers: 2,
 }).run

 ```
 Теперь запустим и посмотрим на процессы + лог файл:
 ```
 $ ruby run.rb
 $ ps x | grep -v grep | grep -E "(se-server|se-worker)"
24670   ??  S      0:00.01 se-server
24671   ??  S      0:00.00 se-worker
24672   ??  S      0:00.00 se-worker
$ head server.log
# Logfile created on 2017-12-25 10:35:02 +0200 by logger.rb/56815
I, [2017-12-25T10:35:02.154033 #24671]  INFO -- : [worker_id: 0] Awesome work!
I, [2017-12-25T10:35:02.155236 #24672]  INFO -- : [worker_id: 1] Awesome work!
 ```
 Все выглядит так, как задумано. Давайте теперь проверим автоматический перезапуск воркера в случае его падения:
 ```
 $ kill -9 24671
 $ ps x | grep -v grep | grep -E "(se-server|se-worker)"
24670   ??  S      0:00.04 se-server
24672   ??  S      0:00.02 se-worker
24730   ??  S      0:00.01 se-worker
$ grep -A 2 -B 2 SIGKILL server.log
I, [2017-12-25T10:35:22.162598 #24672]  INFO -- : [worker_id: 1] Awesome work!
I, [2017-12-25T10:35:22.162715 #24671]  INFO -- : [worker_id: 0] Awesome work!
I, [2017-12-25T10:35:26.073732 #24670]  INFO -- : Worker 0 finished unexpectedly with signal SIGKILL
I, [2017-12-25T10:35:26.080548 #24730]  INFO -- : [worker_id: 0] Awesome work!
I, [2017-12-25T10:35:27.164784 #24672]  INFO -- : [worker_id: 1] Awesome work!
 ```
 Несмотря на то, что процесс воркера PID 24671 был нами убит, процесс сервера через 1 секунду поднял ему замену PID 24730. Продолжая серию убийств примемся за процесс сервера:
 ```
$ kill -9 24670
$ ps x | grep -v grep | grep -E "(se-server|se-worker)"
24672   ??  S      0:00.13 se-worker
24730   ??  S      0:00.13 se-worker
$ tail -n 4 server.log
I, [2017-12-25T10:36:02.175736 #24672]  INFO -- : [worker_id: 1] Awesome work!
I, [2017-12-25T10:36:06.091862 #24730]  INFO -- : [worker_id: 0] Awesome work!
I, [2017-12-25T10:36:07.177564 #24672]  INFO -- : [worker_id: 1] Awesome work!
I, [2017-12-25T10:36:11.093586 #24730]  INFO -- : [worker_id: 0] Awesome work!
 ```
 Теперь мы видим осиротевшие процессы воркеров, которые продолжают молотить задачи. Мы бы могли настроить [monit](https://mmonit.com/monit/documentation/monit.html) для воскрешения мертвого сервер процесса, но это не принесет особой пользы, т.к. новый сервер процесс породит новые воркер процессы вместо того, чтобы побеспокоится о старых. Заброшенные воркер процессы могут стать серьзеной проблемой (особенно при отладке), если их не отстреливать. Откровенно я не понимаю, почему разработчики не побеспокоились об обработке сигнала от умирающего сервер процесса (родительского) в воркер процессах (дочерних), например, с помощью проверки закрытия канала (pipe), как это сделано в Unicorn или Puma.  
