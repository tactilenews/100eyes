# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialogOutbound::Text do
  subject { -> { described_class.new.perform(contributor_id: contributor_id, type: type, text: text, message_id: message_id) } }

  let(:contributor_id) { 234_567 }
  let(:type) { :text }
  let(:text) { 'Some text' }
  let(:message_id) { nil }

  before do
    allow(ENV).to receive(:fetch).with(
      'THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693'
    ).and_return('https://waba-v2.360dialog.io')
    allow(ENV).to receive(:fetch).with('ATTR_ENCRYPTED_KEY',
                                       nil).and_return(Base64.encode64(OpenSSL::Cipher.new('aes-256-gcm').random_key))
  end

  describe 'given no contributor' do
    it 'is expected to throw an ActiveRecord::RecordNotFound error' do
      expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'given a contributor' do
    let(:organization) do
      create(:organization,
             three_sixty_dialog_client_api_key: 'valid_api_key',
             project_name: 'My Project')
    end
    let(:contributor) { create(:contributor, organization: organization, whats_app_phone_number: '+4912345678') }
    let(:contributor_id) { contributor.id }

    before { allow(Sentry).to receive(:capture_exception) }

    describe 'given a text type', vcr: { cassette_name: :three_sixty_dialog_send_text } do
      it 'is successful' do
        subject.call

        expect(Sentry).not_to have_received(:capture_exception)
      end

      context 'given a message id is passed in' do
        let(:message) { create(:message, text: text) }
        let(:message_id) { message.id }

        it "is expected to update the message record's external_id" do
          expect { subject.call }.to (change do
                                        message.reload.external_id
                                      end).from(nil).to('wamid.HBgMNDk0OTEyMzQ1Njc4FQIAERgSNERCRjFEOERFM0RDNDJBMDMyAA==')
        end
      end
    end

    describe 'given a welcome message template type' do
      let(:type) { :welcome_message_template }
      let(:text) { nil }

      it 'is successful', vcr: { cassette_name: :three_sixty_dialog_welcome_message_template } do
        subject.call

        expect(Sentry).not_to have_received(:capture_exception)
      end
    end

    describe 'given a request template type', vcr: { cassette_name: :three_sixty_dialog_send_template } do
      let(:type) { :request_template }
      let(:message) { create(:message, request: create(:request)) }
      let(:message_id) { message.id }

      it 'creates a Message::WhatsAppTemplate record' do
        expect { subject.call }.to change(Message::WhatsAppTemplate, :count).from(0).to(1)
      end

      it 'assigns it to the message record' do
        expect { subject.call }.to (change { message.reload.whats_app_template }).from(nil).to(an_instance_of(Message::WhatsAppTemplate))
      end

      it 'assigns the external_id' do
        subject.call

        whats_app_template = message.whats_app_template
        expect(whats_app_template.external_id).to eq('wamid.HBgMNDk0OTEyMzQ1Njc4FQIAERgSQTZCMzFCREE3NUUxMkE1QzVEAA==')
      end
    end

    describe 'given a direct message template type', vcr: { cassette_name: :three_sixty_dialog_send_direct_message_template } do
      let(:type) { :direct_message_template }
      let(:message) { create(:message, recipient: contributor, broadcasted: false, request: nil) }
      let(:message_id) { message.id }

      it 'creates a Message::WhatsAppTemplate record' do
        expect { subject.call }.to change(Message::WhatsAppTemplate, :count).from(0).to(1)
      end

      it 'assigns it to the message record' do
        expect { subject.call }.to (change { message.reload.whats_app_template }).from(nil).to(an_instance_of(Message::WhatsAppTemplate))
      end

      it 'assigns the external_id' do
        subject.call

        whats_app_template = message.whats_app_template
        expect(whats_app_template.external_id).to eq('wamid.HBgMNDk0OTEyMzQ1Njc4FQIAERgSNEU4MjRGNUIyNTZGMzlBNTRCAA==')
      end
    end
  end
end
