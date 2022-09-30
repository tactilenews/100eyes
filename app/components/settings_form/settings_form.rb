# frozen_string_literal: true

module SettingsForm
  class SettingsForm < ApplicationComponent
    delegate :current_user, to: :helpers
  end
end
