---
title: Трассировка переменных capistrano 
tags: capistrano
---

В [capistrano3](http://capistranorb.com) можно устанваливать (`set`) и извлекать (`fetch`) переменные в процессе деплоя. При этом есть специальная переменная `:print_config_variables`, которая включает режим трассировки переменных.
```ruby
# config/deploy.rb

lock '3.8.2'
 
set :print_config_variables, true
```

```
$ bundle exec cap staging deploy
Config variable set: :print_config_variables => true
Config variable set: :application => "komoku"
Config variable set: :repo_url => "git@github.com:Tensho/komoku.git"
Config variable set: :deploy_to => "/mnt/data/www/komoku"
Config variable set: :format_options => {:command_output=>true, :log_file=>"log/capistrano.log", :color=>:auto, :truncate=>false}
Config variable set: :linked_files => ["config/unicorn.rb", "config/application.yml", "config/database.yml", "config/mongoid.yml", "config/sidekiq.yml"]
...
00:00 git:wrapper
      01 mkdir -p /tmp
    ✔ 01 deploy@10.0.6.201 2.781s
...
```
