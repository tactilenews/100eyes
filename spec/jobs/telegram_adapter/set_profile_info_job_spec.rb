# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::SetProfileInfoJob do
  subject { described_class.new.perform(organization_id: organization.id) }

  let(:organization) do
    create(:organization,
           project_name: 'My project name',
           telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY',
           telegram_bot_username: 'USERNAME',
           messengers_description_text: 'Description, up to 512 characters!',
           messengers_about_text: 'About, up to 120 characters!')
  end
  let(:successful_response) { { 'ok' => true, 'result' => true } }

  before do
    Telegram.reset_bots
    Telegram.bots_config = {
      organization.id => { token: organization.telegram_bot_api_key, username: organization.telegram_bot_username }
    }
    allow(organization.telegram_bot).to receive(:set_my_description).and_return(successful_response)
    allow(organization.telegram_bot).to receive(:set_my_short_description).and_return(successful_response)
    allow(organization.telegram_bot).to receive(:set_my_name).and_return(successful_response)
  end

  describe '#perform' do
    it 'is expected to update the profile info' do
      subject

      project_name = 'My project name'
      expect(organization.telegram_bot).to have_received(:set_my_name).with({ name: project_name })
      description = 'Description, up to 512 characters!'
      expect(organization.telegram_bot).to have_received(:set_my_description).with({ description: description })
      short_description = 'About, up to 120 characters!'
      expect(organization.telegram_bot).to have_received(:set_my_short_description).with({ short_description: short_description })
    end
  end
end
