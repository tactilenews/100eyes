FROM ruby:2.7.2-alpine3.11

# Install dependencies
RUN apk --update add \
    build-base \
    bash \
    git \
    nodejs=~12.15 \
    yarn \
    postgresql-dev=~12.4 \
    postgresql-client=~12.4 \
    tzdata \
    libxslt-dev \
    libxml2-dev \
    imagemagick \
    less

RUN mkdir -p /app
WORKDIR /app
CMD ["bundle", "exec", "rails", "server"]


COPY Gemfile Gemfile.lock ./
RUN gem install bundler
RUN bundle install

ENV RAILS_ENV development
ENV NODE_ENV production

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

RUN bundle exec rake webpacker:compile
ENV RAILS_ENV production
