#    scratch
#    alpine:3.12
FROM ruby:2.7.2-alpine

RUN apk --no-cache add --update build-base git

WORKDIR /blog

COPY Gemfile* ./

RUN bundle install --jobs 4 --without development

COPY . .

EXPOSE 4000

CMD ["jekyll", "serve", "--host", "0.0.0.0"]
