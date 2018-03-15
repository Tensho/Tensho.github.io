---
title: ActiveRecord Connection Pool требует к себе внимания
date: 2018-03-15
tags: activerecord connection pool globalize sidekiq
---

Любому, кто работает с Rails продолжительное время, известно, что ActiveRecord управляет соединениями с базой данных через пул ([Connection Pool](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html)). Пул соединений синхронизирует доступ потока к лимитированному числу соединений к БД. Базовая идея такая, что каждый поток берет соединение из пула, использует его и кладет обратно. Сам ConnectionPool полностью потокобезопасный и исключает ситуацию использования одного и того же соединения двумя потоками в одно и тоже время. Также в его обязанности входит обработка случаев, когда потоков больше соединений. Т.е. если соединения в пуле закончились, но в текущем потоке требуется новое, то поток блокируется до тех пор, пока какой-нибудь другой поток не освободит соединение.

Соединение можно получить 3 способами: автоматический, полуавтоматичесий и ручной. Самый простой способ просто получить `ActiveRecord::Base.connection` для получения соединения, а положить при помощи `ActiveRecord::Base.clear_active_connections!`. Полуавтоматический режим выглядит в виде работы с соединением в рамках блока метода `ActiveRecord::Base.connection_pool.with_connection(&block)`. Ну и для настоящих гиков есть `ActiveRecord::Base.connection_pool.checkout` для ручного забора и `ActiveRecord::Base.connection_pool.checkin` для возврата соединения. Очень важно следить за тем, чтобы соединения возвращались в пул после использования. В противном случае можно остаться без доступных соединений. Например, в Rails 4 возвратом активных соединений с базой данных занимается Rack Middleware – [`ActiveRecord::ConnectionAdapters::ConnectionManagement`](https://github.com/rails/rails/blob/v4.2.10/activerecord/lib/active_record/connection_adapters/abstract/connection_pool.rb#L655) в рамках жизненного цикла запроса-ответа, а в Rails 5 эту роль на себя взял [Executor](). Для Sidekiq есть встроенный Server Middleware – [`Sidekiq::Middleware::Server::ActiveRecord`](https://github.com/mperham/sidekiq/blob/master/lib/sidekiq/middleware/server/active_record.rb#L18) – для тех же целей.

Давайте рассмотрим базовые примеры развертывания Rails/Sidekiq приложения и базы данных:

 ![ActiveRecord Connection Pool]({{ "/assets/activerecord-connection-pool.svg" | absolute_url }})

Нужно быть внимательным при установке значения размера ActiveRecord пула соединений. По умолчанию Rails 5 запускается на Puma с 5 потоками, и следовательно с пулом в 5 соединений ActiveRecord. Но при конфигурировани production окружения фактически необходимо выровнять (или сделать чуть больше, как будет сказано ниже) размер ActiveRecord пула и обработчиков (воркеров) . Если же используется Unicorn, который запускает воркеры на процессах, то обычно в [`config/unicorn.rb`](https://github.com/defunkt/unicorn/blob/master/examples/unicorn.conf.rb) прописывают `after_fork` хук, в котором ActiveRecord соединения мастера выкидываются на помойку, а каждый форкнутый воркер переподнимает свой собственный пул:

    preload_app true

    before_fork do |server, worker|
      defined?(ActiveRecord::Base) && ActiveRecord::Base.connection.disconnect!
    end

    after_fork do |server, worker|
      defined?(ActiveRecord::Base) && ActiveRecord::Base.establish_connection
    end

Так как Unicorn однопоточный, то в принципе 1 соединения в пуле достаточно.

Sidekiq описывает кол-во воркеров посредством [`:concurrency:`](https://github.com/mperham/sidekiq/wiki/Advanced-Options#concurrency) опции. По хорошему установки размера пула соедниений для Rails и Sidekiq должны быть разными, но часто оставляют максимальное число, которое обычно за Sidekiq. Например, по умолчанию Sidekiq создает 25 воркеров в разных потоках, а следовательно ему нужен ActiveRecord пул минимум на 25 соединений. Если выставить `pool: 25`, то воркеры Unicorn получат слишком большого размера пул. В этом нет ничего страшного, т.к. обхекты соединения создаются лениво. Однако, для аккуратного учета лучше заранее выписывать колчиество соединений на каждого протребителя базы данных. 

Почему я всем этим озадачился и копнул вглубь? Есть такой гем [globalize](https://github.com/globalize/globalize), который патчит ActiveRecord, чтобы позволить декларативно описывать интернационализированные (глобализированные) атрибуты модели. Под капотом Globalize опирается на дополнительные таблицы с переводами (`<model_transaltions>`) и делает INNER JOIN с основной таблицей каждый раз, когда мы просим получить глобализированный атрибут.

 ![Globalize Tables]({{ "/assets/globalize-tables.svg" | absolute_url }})

Недавно я обнаружил, что при подключении этого гема в рамках standalone (без Rails) Sidekiq у меня начала вываливаться вот такая до боли знакомая ошибка:

    ActiveRecord::ConnectionTimeoutError: could not obtain a database connection within 5.000 seconds (waited 5.000 seconds)

 Оказывается, `globalize` делает запросы к базе данных во время отработки декларации `translates` в классе ActiveRecord модели, чтобы [проверить наличие колонок для глобализированных атрибутов](https://github.com/globalize/globalize/blob/master/lib/globalize/active_record/act_macro.rb#L8). А это значит, что вытягивается 1 соединение из ActiveRecord пула и привязывается к текущему потоку. А текущий поток – это main – в котором идет инициализация окружения, в том числе и зачитывания классов ActiveRecord моделей! Следовательно, еще до того, как начнут свою работу Sidekiq воркеры, globalize уже спер одно соединение. Не зря есть тонкая фраза в документации Sidekiq "Advanced Options", раздел ["Concurrency"](https://github.com/mperham/sidekiq/wiki/Advanced-Options#concurrency):

> Set the pool setting to something close or equal to the number of threads

Словосочетание "something close" как раз про мой случай. Очевидно, что увеличение размера пула на 1 соединение решило проблему, но это наводит на одну важную мысль – надо понимать, как работают библиотеки, которыми мы пользуемся. Я не говорю про каждый винтик, но вобщем понимание архитектуры может очень помочь. Кстати я решил на всякий случай добавить +1 соединение на случай, если кто-то решит добавить библиотеку, которая выкинет что-то похожее в отдельном потоке в тот момент, когда я буду в отпуске ^_^

Альтернативным вариантом было бы делать автозагрузку ([Autoloading](http://guides.rubyonrails.org/autoloading_and_reloading_constants.html)) моделей из потоков воркеров, как это делает Rails development окружение, но эта тема достаточно сложная сама по себе, не говоря уже о том, чтобы ее аккуратно подкинуть к одинокому Sidekiq. 

Читайте внимательно документацию библиотек, разбирайте их исходные коды, старайтесь там найти реальное применение шаблонов проектирования, вносите вклад в их развитие.
