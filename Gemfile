# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.0.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.7.1'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 6.4.2'
# Use Active Storage variant
gem 'image_processing', '~> 1.12'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'pry-rails'
  gem 'rspec-rails'
end

group :development do
  gem 'bullet'
  gem 'listen', '>= 3.0.5', '< 3.8'
  gem 'rubocop-rails', require: false

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
end

group :test do
  # Adds support for Capybara system testing
  gem 'capybara', '>= 3.38.0'
  gem 'cuprite'
  gem 'db-query-matchers'
  gem 'faker'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'activestorage-validator', '~> 0.2.2'
gem 'acts-as-taggable-on'
gem 'browser'
gem 'counter_culture', '~> 3.3'
gem 'delayed_job_active_record', '~> 4.1'
gem 'jwt'
gem 'kramdown', '~> 2.4'
gem 'pg_search'
gem 'phony_rails'
gem 'rails-settings-cached', '~> 2.8'
gem 'valid_email2', '~> 4.0'
gem 'view_component', '~> 2.83.0'

# Middleware
gem 'rack-attack', '~> 6.6'

# Channel adapters
gem 'postmark-rails'
gem 'telegram-bot'
gem 'threema', git: 'https://github.com/threemarb/threema.git', branch: 'master'
gem 'twilio-ruby'

# User management
gem 'active_model_otp'
gem 'clearance'
gem 'rqrcode'

# Error reporting
gem 'sentry-delayed_job'
gem 'sentry-rails'
gem 'sentry-ruby'

# Admin
gem 'administrate'
gem 'administrate_exportable'
gem 'administrate-field-active_storage'
gem 'administrate-field-jsonb'

# Notifications
gem 'noticed', '~> 1.6'

# Charts
gem 'groupdate'

# Pagination
gem 'kaminari', '~> 1.2'

# Encrypt attrs
gem 'attr_encrypted'

gem 'data_migrate', '~> 9.2.0'
