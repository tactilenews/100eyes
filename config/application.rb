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

    config.autoload_paths += Dir[Rails.root.join('app/models/validators')]

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

    # Allow SVG files to be served without forced downloads. This is disabled by default,
    # because SVG files can be used for XSS attacks. We do only render user-uploaded
    # SVG files using `img` tags, which won’t execute any inline JavaScript embedded into
    # SVG files. Additionally, our Content Security Policy disallows inline JavaScript.
    config.active_storage.content_types_to_serve_as_binary -= ['image/svg+xml']

    # Serve JSON files inline, i.e. without forcing a download. This allows
    # us to preview raw message data, which is often stored as JSON, directly
    # in the browser.
    config.active_storage.content_types_allowed_inline << 'application/json'
    # This only works if all tenants use the same twilio subaccount.
    config.middleware.use Rack::TwilioWebhookAuthentication,
                          ENV['TWILIO_AUTH_TOKEN'],
                          '/whats_app/webhook',
                          '/whats_app/status',
                          '/whats_app/errors'
  end
end
