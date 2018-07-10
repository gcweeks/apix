FROM ruby:2.5

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install software-properties-common apt-utils nodejs build-essential

RUN mkdir /rails
WORKDIR /rails

COPY ./rails/Gemfile ./rails/Gemfile.lock ./

RUN bundle install -j 20

COPY ./rails ./
