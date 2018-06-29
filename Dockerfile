FROM ruby:2.5.1-alpine

RUN apk add --update \
  build-base \
  libxml2-dev \
  libxslt-dev \
  postgresql-dev \
  postgresql-client \
  tzdata \
  git \
  && rm -rf /var/cache/apk/*

ENV APP_HOME /src

RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ENV BUNDLE_PATH=/bundle

ADD . $APP_HOME

RUN bundle install

CMD ['ash']
