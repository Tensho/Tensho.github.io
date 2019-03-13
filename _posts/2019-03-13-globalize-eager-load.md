---
title: Нетерпеливый Globalize и неоднозначный ActiveRecord
date: 2019-03-13
tags: globalize eager load activerecord
---

История еще одного расследования. Недавно мой проект частично перешел на стратегию сборки Rails приложений AMI + EBS через Packer + Terraform. В рамках этого перехода всплыла одна интересная деталь касающаяся сразу нескольких библиотек – [`rake`](https://github.com/ruby/rake), [`rails-observers`](https://github.com/rails/rails-observers), [`globalize`](https://github.com/globalize/globalize). Случилось так, что при [компиляции ассетов](https://guides.rubyonrails.org/asset_pipeline.html#precompiling-assets) (`rake assets:precompile`) на Packer Builder инстансе вывалилась ошибка подключения к БД:  

    amazon-ebsvolume: PG::ConnectionBad: timeout expired

"Хмн, а накой нам подключатся к базе данных, если мы просто хотим работать с Assets Pipeline на данном шаге? Насоклько я помню, ActiveRecord весьма ленив (в хорошем смысле этого слова) и не затребует подключение до тех пор, пока это дейтсвительно необходимо." – подумал я. И приступил к глубокому анализу (с прокруткой) цепочки вызовов в бектрейсе ошибки:

1. `rake assets:precompile` загружает окружение Rails.
2. Rails загружает основную конфигурацию приложения, в котором зарегистрированы ActiveRecord Observers:

```ruby
# config/application.rb

config.active_record.observers = %i[data_sync_observer]
````
    
3. Rails загружает `railtie` гемов, включая `rails-observers` гем
4. Гем `rails-observers` вычитывает конфигурацию и подгружает класс [наблюдателя](https://ru.wikipedia.org/wiki/%D0%9D%D0%B0%D0%B1%D0%BB%D1%8E%D0%B4%D0%B0%D1%82%D0%B5%D0%BB%D1%8C_(%D1%88%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD_%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)) согласно конвенции.
5. `DataSyncObserver` класс имеет код, который ссылается на классы моделей:

```ruby
# app/observers/data_sync_observer.rb

class DataSyncObserver < ActiveRecord::Observer
  OBSERVED_CLASSES = [
    Sector, Sector::Translation,
    Company, Company::Translation
  ]
  
  ...
end
```

6. В `rake` задачах срабатывает автоподгрузка (даже в production окружении) по умолчанию:

```ruby
# config/environments/production.rb

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true
  
  ...
end
```

Так сделано для увеличения производительности, т.к. часть кода может быть просто не нужна для выполнения конкретной задачи. Следовательно `rails` загружает первый попавшийся класс модели `Sector`.

7. Модель `Sector` декларирует переводимые атрибуты с помощью [`translates`](https://github.com/globalize/globalize/blob/master/lib/globalize/active_record/act_macro.rb#L4) `globalize` макроса:

```ruby
class Sector < ApplicationRecord
  translates :name,
             :description
             
  ...
end
```

8. `globalize` вызывает [`check_columns!`](https://github.com/globalize/globalize/blob/master/lib/globalize/active_record/act_macro.rb#L53) для сбора информации о таблице переводов из БД. Бам! "А ведь было уже такое! Опять нетерпеливый Globalize!" – в моей голове всплыли [воспоминания]({% post_url 2018-03-15-activerecord-connection-pool-globalize-sidekiq %}).



В надежде понять задумку автора `globalize` делать досрочное подключение к БД я побрел на GitHub:

1. В ["rails asset:precompile attempts to connect to DB because of globalize"](https://github.com/globalize/globalize/issues/601) Issue признают косяк и говорят что пофиксили. 
2. ["Check if there's a connection before table_exists?"](https://github.com/globalize/globalize/pull/602) PR фактически вводит проверку подключения в виде условия с вызовом [`connected?`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionHandling.html#method-i-connected-3F) метода.
3. Там же в комментариях ссылаются на ["Support for Rails 5.1"](https://github.com/globalize/globalize/pull/619#commitcomment-22174073) PR, в котором вызов `connected?` заменили на перехват исключения [`ActiveRecord::NoDatabaseError`](https://api.rubyonrails.org/classes/ActiveRecord/NoDatabaseError.html). Автор резонно утверждает, что при запуске некоторых `globalize` юнит-тестов подключения к БД действительно нет.
4. Однако, вот не задача, **ActiveRecord просто пробрасывает оригинальное исключение в случае, когда соединение к БД установить не удалось**. Например, `pg` выдает `PG::ConnectionBad`. Вполне логично было бы ожидать какое-то более абтрактное исключение вроде `ActiveRecord::NoConnectionError`, но увы. Также в ["ActiveRecord::NoDatabaseError not raised"](https://github.com/rails/rails/issues/32994) Issue поднимает аналогичный вопрос в контексте обработки исключений MySQL и Postgres адаптеров в условиях отсутствия БД. Вот как обрабатывает исключения прилетающие из [`ActiveRecord::ConnectionAdapters::PostgreSQLAdapter`]( https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L48):

```ruby
def postgresql_connection(config)
  ...
  ConnectionAdapters::PostgreSQLAdapter.new(conn, logger, conn_params, config)
rescue ::PG::Error => error
  if error.message.include?("does not exist")
    raise ActiveRecord::NoDatabaseError
  else
    raise
  end
end
```
 
А так [`ActiveRecord::ConnectionAdapters::Mysql2Adapter`](https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L24) ищет подстроку `"Unknown database"`:

```ruby
def mysql2_connection(config)
  ...
  ConnectionAdapters::Mysql2Adapter.new(client, logger, nil, config)
rescue Mysql2::Error => error
  if error.message.include?("Unknown database")
    raise ActiveRecord::NoDatabaseError
  else
    raise
  end
end
```

Но это уже ньюансы, а сакраментальный там следующий пассаж, подводящий итог всему приключению:

<blockquote>
However, that doesn't help Globalize, because there are plenty of connection errors that we don't want to cover up. That's better addressed from a different angle: error handling aside, it's very bad form for a model definition to cause a database connection. Globalize is designed incorrectly: it should not cause a database connection when loading the model definition, and should instead hook the model's load_schema! to run at the right time.
</blockquote>
 
Да, девочки и мальчики, быть нетерпеливым не всегда хорошо.

Поиск решения в процессе...

Благодарочка коллеге [Артуру](https://twitter.com/artlugovoy), который навел на первичный GitHub тред по теме.

### Ссылки

- [`MySQL::Error`](https://github.com/brianmario/mysql2/blob/master/lib/mysql2/error.rb)
- `PG::Error` [definitions](https://bitbucket.org/ged/ruby-pg/src/fddea15f846d3f900665fbe8760fcd4e90bc9b70/ext/errorcodes.def) and [class generator](https://bitbucket.org/ged/ruby-pg/src/fddea15f846d3f900665fbe8760fcd4e90bc9b70/ext/errorcodes.rb)
