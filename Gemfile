# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.0.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.4'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 5.5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Enable component-driven frontend architecture
gem 'view_component', '~> 2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'pry-rails'
  gem 'rspec-rails'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.8'
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'rubocop-rails', require: false
  gem 'web-console', '>= 3.3.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'foreman'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'db-query-matchers'
  gem 'faker'
  gem 'timecop'
  gem 'vcr'
  gem 'webdrivers', require: false
  gem 'webmock'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'activestorage-validator', '~> 0.1.4'
gem 'acts-as-taggable-on'
gem 'counter_culture', '~> 2.9'
gem 'delayed_job_active_record', '~> 4.1'
gem 'jwt'
gem 'kramdown', '~> 2.3'
gem 'pg_search'
gem 'phony_rails'
gem 'rails-settings-cached', '~> 2.8'
gem 'valid_email2', '~> 4.0'

# Middleware
gem 'rack-attack', '~> 6.5'

# Channel adapters
gem 'postmark-rails'
gem 'telegram-bot'
gem 'threema', git: 'https://github.com/tactilenews/threema.git', branch: 'master'

# User management
gem 'active_model_otp'
gem 'clearance'
gem 'rqrcode'

# Error reporting
gem 'sentry-delayed_job'
gem 'sentry-rails'
gem 'sentry-ruby'

# Frontend
gem 'cssbundling-rails'
gem 'jsbundling-rails'
