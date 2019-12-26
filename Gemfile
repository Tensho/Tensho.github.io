# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

group :jekyll_plugins do
  gem 'github-pages'     # maintaining a local Jekyll environment in sync with GitHub Pages
  gem 'jekyll-feed'      # RSS
  gem 'jekyll-paginate'
end

group :development do
  gem 'overcommit'
end

group :test do
  gem 'html-proofer'
end
