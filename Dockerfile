#    scratch
#    alpine:3.7
FROM ruby:2.5.1-alpine

RUN apk --no-cache add --update build-base git

WORKDIR /blog

COPY Gemfile* ./

RUN bundle install --jobs 4

COPY . .

EXPOSE 4000

CMD ["jekyll", "serve", "--host", "0.0.0.0"]
