# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 2.7.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.10'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Use Webpack & Co.
gem 'webpacker', '~> 5'

# Enable component-driven frontend architecture
gem 'view_component', '~> 2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'pry-rails'
  gem 'rspec-rails'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'rubocop-rails', require: false
  gem 'web-console', '>= 3.3.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'db-query-matchers'
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'sucker_punch', '~> 2.1'
gem 'telegram-bot'

gem 'pg_search'

gem 'valid_email2', '~> 3.5'

gem 'counter_culture', '~> 2.6'

gem 'activestorage-validator', '~> 0.1.3'

gem 'rack-attack', '~> 6.3'

gem 'acts-as-taggable-on'
gem 'jwt'
gem 'mini_magick', '~> 4.10'

# TODO: Move into group :development, :test once uberspace setup is removed
gem 'dotenv-rails'
# TODO: Move into group :development once uberspace setup is removed
gem 'listen', '>= 3.0.5', '< 3.3'
gem 'rails-settings-cached', '~> 2.3'

gem 'kramdown', '~> 2.3'

gem 'postmark-rails'
