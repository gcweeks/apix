FROM ruby:2.5

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install software-properties-common apt-utils nodejs build-essential

RUN mkdir /app
WORKDIR /app

COPY ./app/Gemfile app/Gemfile.lock ./

RUN bundle install -j 20

COPY ./app ./
