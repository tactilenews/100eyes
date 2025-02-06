# frozen_string_literal: true

module TelegramAdapter
  class SetProfileInfoJob < ApplicationJob
    def perform(organization_id:); end
  end
end
