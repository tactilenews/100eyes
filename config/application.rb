# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.generators.assets = false
    config.generators.helper = false

    config.active_job.queue_adapter = :delayed_job

    config.i18n.available_locales = %i[de en]
    config.i18n.default_locale = :de
    config.time_zone = 'Berlin'
    config.i18n.fallbacks = true

    # Serve JSON files inline, i.e. without forcing a download. This allows
    # us to preview raw message data, which is often stored as JSON, directly
    # in the browser.
    config.active_storage.content_types_allowed_inline << 'application/json'
  end
end
