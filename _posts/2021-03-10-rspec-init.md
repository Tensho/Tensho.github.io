---
title: RSpec Init
date: 2021-03-10
tags: rspec
---

Назад к основам – инициализация RSpec для быстрых экспериментов с тестами. Добавляем гем в `Gemfile`:

```ruby
# Gemfile

source 'https://rubygems.org'

gem 'rspec'
```

Устанавливаем гем и инициализируем RSpec:

```shell
$ bundle
$ rspec --init
  create   .rspec
  create   spec/spec_helper.rb
```

Добавляем примитивный тест:

```ruby
require 'spec_helper'

RSpec.shared_examples 'truth' do
  it 'eternal truth' do
    expect(true).to eq(true)
  end
end

class Human
  def run
    'Run!'
  end
end

RSpec.describe Human do
  include_examples 'truth'

  it 'runs' do
    expect(subject.run).to eq('Run!')
  end
end
```
Экспеременитируем:

```shell
$ rspec
Run options: include {:focus=>true}

All examples were filtered out; ignoring {:focus=>true}

Randomized with seed 31170

Human
  runs
  eternal truth

Finished in 0.00148 seconds (files took 0.1106 seconds to load)
2 examples, 0 failures

Randomized with seed 31170
```
