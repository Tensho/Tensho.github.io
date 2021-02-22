---
title: Rails Routing Path vs URL
date: 2021-02-22
tags: rails routing path url
---

Представим, что у нас имеется простой ресурсный маршрут для пользователей:

```
# config/routes.rb

resources :users
```

В Rails впилено куча магии для поддержки [маршрутных хелперов](https://guides.rubyonrails.org/routing.html#path-and-url-helpers), чтобы на базе ресурса можно было выдавать разного рода ссылки. Например, `user_path` возвращает относительный путь, а `user_url`  – абсолютный (схема, хост, порт). По умолчанию во всех Rails окружениях не настроены опции для составления полноценного URL и попытка выписать себе абсолютную ссылку заканчивается вполне ождиаемым исключением:

```
> Rails.application.routes.default_url_options
{}
> Rails.application.routes.url_helpers.users_path
"/users"
> Rails.application.routes.url_helpers.users_url
Traceback (most recent call last):
        1: from (irb):3
ArgumentError (Missing host to link to! Please provide the :host parameter, set default_url_options[:host], or set :only_path to true)
```

Для разных компонентов Rails, которые работают вне цикла запроса-ответа, есть отдельная настройка `default_url_options`. Например, хост для ActionMailer можно настроить через `Rails.application.config.action_mailer.default_url_options`, чтобы все ссылки в письме были "абсолютными". Сейчас [обсуждается вариант унификаиции этой настройки для всех компонентов](https://github.com/rails/rails/issues/39566), но пока что нужно выставлять для каждого отдельно. В частности для примера выше нужно явно выставить соответствующие опции в `Rails.application.routes.default_url_options`:

```
> Rails.application.routes.default_url_options = { protocol: 'https', host: 'www.example.com', port: 3000 }
> Rails.application.routes.url_helpers.users_path
"/users"
> Rails.application.routes.url_helpers.users_url
"https://www.example.com:3000/users"
```

Если не указывать схему и порт, то по умолчанию будет использоваться `http` и неявный 80 порт.

ActiveStorage является еще одним компонентом, который опирается на маршртуные хелперы.

```
# app/models/user.rb

class User < ApplicationRecord
  has_one_attached :avatar
end
```

```
> Rails.application.routes.default_url_options
{}
> Rails.application.routes.url_helpers.url_for(user.avatar)
Traceback (most recent call last):
        1: from (irb):2
ArgumentError (Missing host to link to! Please provide the :host parameter, set default_url_options[:host], or set :only_path to true)
> Rails.application.routes.default_url_options = { host: 'www.example.com' }
> Rails.application.routes.url_helpers.url_for(user.avatar)
"http://www.example.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBEQT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--ba7683b438ba5be31fac57cba6385b2e15cde4db/headspace.png"
```

В общем, если надо выставлять абсолютные ссылки, то не забываем указывать для этого схему, хост и порт. Ну по крайней мере хост ^_^
