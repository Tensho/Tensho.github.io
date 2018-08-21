---
title: Rails Database Migration Cheatsheet
date: 2018-06-26
tags: rails database migrations cheatsheet
---

Все время забываю некоторые составные rake команды ActiveRecord мигратора баз данных, поэтому решил выписать шпаргалку:

```
db:setup = db:create + db:schema:load + db:seed
db:reset = rails db:drop db:setup
db:rollback = db:migrate:down + db:schema:dump
db:migrate = db:migrate:up + db:schema:dump
db:migrate:redo = db:rollback + db:migrate
```
