# frozen_string_literal: true

module TelegramAdapter
  class SetProfileInfoJob < ApplicationJob
    def perform(organization_id:)
      organization = Organization.find(organization_id)

      bot = organization.telegram_bot
      bot.set_my_name(name: organization.project_name)
      bot.set_my_description(description: organization.messengers_description_text)
      bot.set_my_short_description(short_description: organization.messengers_about_text)
    end
  end
end
