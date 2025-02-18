# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound::Text do
  let(:adapter) { described_class.new }
  let(:organization) do
    create(:organization, name: '100eyes', telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY', telegram_bot_username: 'USERNAME')
  end
  let(:contributor) { create(:contributor, telegram_id: 4, organization: organization) }
  let(:contributor_id) { contributor.id }
  let(:message) { create(:message, text: text, broadcasted: true, recipient: contributor, organization: organization) }
  let(:successful_response) do
    {
      'ok' => true,
      'result' =>
        {
          'message_id' => 12_345_678,
          'from' => {
            'id' => 12_345_678,
            'is_bot' => true,
            'first_name' => '@USERNAME',
            'username' => 'USERNAME'
          },
          'chat' => {
            'id' => 12_345_678,
            'first_name' => contributor.first_name,
            'last_name' => contributor.last_name,
            'username' => contributor.username,
            'type' => 'private'
          },
          'date' => Time.current.to_i,
          'text' => text
        }
    }
  end
  let(:text) { 'Forgot to ask: How are you?' }

  before do
    Telegram.reset_bots
    Telegram.bots_config = {
      organization.id => { token: organization.telegram_bot_api_key, username: organization.telegram_bot_username }
    }
    allow(organization.telegram_bot).to receive(:send_message).and_return(successful_response)
  end

  it 'sanity-check: telegram bot is not nil' do
    expect(organization.telegram_bot).to be_truthy
  end

  describe '#perform' do
    subject { -> { adapter.perform(contributor_id: contributor_id, text: text, message: message) } }

    let(:expected_message) { { chat_id: 4, text: text, parse_mode: :HTML } }

    it 'sends the message with TelegramBot' do
      expect(organization.telegram_bot).to receive(:send_message).with(expected_message)

      subject.call
    end

    context 'successful sent' do
      let(:external_id) { successful_response.with_indifferent_access[:result][:message_id].to_s }

      it 'marks the message as sent' do
        expect { subject.call }.to change { message.reload.sent_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it "saves the message's external id" do
        expect { subject.call }.to change { message.reload.external_id }.from(nil).to(external_id)
      end
    end

    context 'text message, no message' do
      let(:message) { nil }
      let(:welcome_message) { [organization.onboarding_success_heading, organization.onboarding_success_text].join("\n") }
      let(:text) { welcome_message }

      it 'does not throw an error' do
        expect { subject.call }.not_to raise_error
      end
    end

    describe 'Unknown contributor' do
      let(:contributor_id) { 564_321 }

      it 'throws an error' do
        expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
