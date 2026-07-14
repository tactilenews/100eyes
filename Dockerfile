FROM ruby:3.2.2-alpine3.16

ARG git_commit_sha
ARG git_commit_date

# Install dependencies
RUN apk --update add \
    build-base \
    bash \
    git \
    nodejs-current \
    npm \
    postgresql-dev \
    postgresql-client \
    tzdata \
    libxslt-dev \
    libxml2-dev \
    imagemagick \
    less \
    libsodium

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

RUN mkdir -p /app
WORKDIR /app
CMD ["bundle", "exec", "rails", "server"]

ENV RAILS_ENV=production
COPY Gemfile Gemfile.lock ./
RUN gem install bundler
RUN bundle install

ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm install --production=false

COPY . .

RUN npm run build:js
RUN npm run build:css

ENV GIT_COMMIT_SHA=$git_commit_sha
ENV GIT_COMMIT_DATE=$git_commit_date
