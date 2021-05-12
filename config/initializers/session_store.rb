# frozen_string_literal: true

Rails.application.config.session_store :cookie_store, key: '_app_session', same_site: :lax
