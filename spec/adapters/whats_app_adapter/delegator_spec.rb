# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::Delegator do
  let(:organization) { create(:organization) }
  let(:adapter) { described_class.new(organization) }
  let(:request) { create(:request, organization: organization) }
  let!(:message) do
    create(:message,
           text: 'Tell me your favorite color, and why.',
           broadcasted: true,
           recipient: contributor,
           request: request)
  end
  let(:contributor) { create(:contributor, email: nil, organization: organization) }

  describe '::send!' do
    subject { -> { adapter.send!(message) } }

    context 'with 360dialog configured' do
      before do
        organization.update(three_sixty_dialog_client_api_key: 'valid_api_key')
        allow(WhatsAppAdapter::ThreeSixtyDialogOutbound).to receive(:send!)
        allow(WhatsAppAdapter::TwilioOutbound).to receive(:send!)
      end

      it 'it is expected to send the message with 360dialog' do
        expect(WhatsAppAdapter::ThreeSixtyDialogOutbound).to receive(:send!).with(message)

        subject.call
      end

      it 'it is expected not to send it with Twilio' do
        expect(WhatsAppAdapter::TwilioOutbound).not_to receive(:send!)

        subject.call
      end
    end

    context 'without 360dialog configured' do
      before do
        allow(WhatsAppAdapter::ThreeSixtyDialogOutbound).to receive(:send!)
        allow(WhatsAppAdapter::TwilioOutbound).to receive(:send!)
      end

      it 'it is expected not to send the message with 360dialog' do
        expect(WhatsAppAdapter::ThreeSixtyDialogOutbound).not_to receive(:send!)

        subject.call
      end

      it 'it is expected to send it with Twilio' do
        expect(WhatsAppAdapter::TwilioOutbound).to receive(:send!).with(message)

        subject.call
      end
    end
  end

  describe '::send_welcome_message!' do
    subject { -> { adapter.send_welcome_message!(contributor, organization) } }

    context 'with 360dialog configured' do
      before do
        organization.update(three_sixty_dialog_client_api_key: 'valid_api_key')
        allow(WhatsAppAdapter::ThreeSixtyDialogOutbound).to receive(:send_welcome_message!)
        allow(WhatsAppAdapter::TwilioOutbound).to receive(:send_welcome_message!)
      end

      it 'it is expected to send the welcome message with 360dialog' do
        expect(WhatsAppAdapter::ThreeSixtyDialogOutbound).to receive(:send_welcome_message!).with(contributor, organization)

        subject.call
      end

      it 'it is expected not to send the welcome message with Twilio' do
        expect(WhatsAppAdapter::TwilioOutbound).not_to receive(:send_welcome_message!)

        subject.call
      end
    end

    context 'without 360dialog configured' do
      before do
        allow(WhatsAppAdapter::ThreeSixtyDialogOutbound).to receive(:send_welcome_message!)
        allow(WhatsAppAdapter::TwilioOutbound).to receive(:send_welcome_message!)
      end

      it 'it is expected not to send the welcome message with 360dialog' do
        expect(WhatsAppAdapter::ThreeSixtyDialogOutbound).not_to receive(:send_welcome_message!)

        subject.call
      end

      it 'it is expected to send the welcome message with Twilio' do
        expect(WhatsAppAdapter::TwilioOutbound).to receive(:send_welcome_message!).with(contributor, organization)

        subject.call
      end
    end
  end
end
