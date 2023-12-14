# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound::Text do
  let(:adapter) { described_class.new }
  let(:contributor) { create(:contributor, telegram_id: 4) }
  let(:message) { create(:message, text: text, broadcasted: true, recipient: contributor) }
  let(:successful_response) do
    {
      'ok' => true,
      'result' =>
        {
          'message_id' => 12_345_678,
          'from' => {
            'id' => 12_345_678,
            'is_bot' => true,
            'first_name' => "@#{Telegram.bots[:default].username}",
            'username' => Telegram.bots[:default].username
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
  before { allow(Telegram.bot).to receive(:send_message).and_return(successful_response) }

  describe '#perform' do
    subject { adapter.perform(contributor_id: contributor.id, text: text, message: message) }

    let(:expected_message) { { chat_id: 4, text: text, parse_mode: :HTML } }

    it 'sends the message with TelegramBot' do
      expect(Telegram.bot).to receive(:send_message).with(expected_message)

      subject
    end

    context 'successful delivery' do
      let(:external_id) { successful_response.with_indifferent_access[:result][:message_id].to_s }

      it 'marks the message as received' do
        expect { subject }.to change { message.reload.received_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it "saves the message's external id" do
        expect { subject }.to change { message.reload.external_id }.from(nil).to(external_id)
      end
    end

    context 'text message, no message' do
      let(:message) { nil }
      let(:welcome_message) { [Setting.onboarding_success_heading, Setting.onboarding_success_text].join("\n") }
      let(:text) { welcome_message }

      it 'does not throw an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
