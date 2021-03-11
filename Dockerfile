FROM ruby:3.0.0-alpine

# Install dependencies
RUN apk --update add \
    build-base \
    bash \
    git \
    nodejs \
    yarn \
    postgresql-dev=~13.2 \
    postgresql-client=~13.2 \
    tzdata \
    libxslt-dev \
    libxml2-dev \
    imagemagick \
    less \
    libsodium

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
