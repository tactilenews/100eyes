# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound::Photo do
  let(:adapter) { described_class.new }
  let(:organization) do
    create(:organization, name: '100eyes', telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY', telegram_bot_username: 'USERNAME')
  end
  let(:contributor) { create(:contributor, telegram_id: 4, organization: organization) }
  let(:message) { create(:message, :with_file, text: 'Did you get my image file?', broadcasted: true, recipient: contributor) }
  let(:organization_id) { organization.id }
  let(:contributor_id) { contributor.id }
  let(:photos) { create_list(:file, 2, message: message) }
  let(:media) { photos.map { |photo| ActiveStorage::Blob.service.path_for(photo.attachment.blob.key) } }
  let(:successful_response) do
    {
      'ok' => true,
      'result' =>
        [{
          'message_id' => 12_345_678,
          'from' => {
            'id' => 1_271_814_880,
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
          'photo' =>
          [{
            'file_id' => 'someFileId',
            'file_unique_id' => 'someUniqueFileId',
            'file_size' => 2282,
            'width' => 90,
            'height' => 90
          },
           {
             'file_id' => 'someFileIdVariant',
             'file_unique_id' => 'someFileUniqueIdVariant',
             'file_size' => 24_993,
             'width' => 320,
             'height' => 320
           },
           {
             'file_id' => 'someFileIdOtherVariant',
             'file_unique_id' => 'someFileUniqueIdOtherVariant',
             'file_size' => 58_873,
             'width' => 640,
             'height' => 640
           }],
          'caption' => 'here is an image file'
        }]
    }
  end

  before do
    Telegram.reset_bots
    Telegram.bots_config = {
      organization.id => { token: organization.telegram_bot_api_key, username: organization.telegram_bot_username }
    }
    allow(organization.telegram_bot).to receive(:send_media_group).and_return(successful_response)
  end

  describe '#perform' do
    before do
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open)
        .with(media.first)
        .and_return(ActiveStorage::Blob.service.path_for(photos.first.attachment.blob.key))
      allow(File).to receive(:open)
        .with(media.second)
        .and_return(ActiveStorage::Blob.service.path_for(photos.second.attachment.blob.key))
    end

    subject do
      lambda {
        adapter.perform(organization_id: organization_id, contributor_id: contributor_id, media: media, message: message)
      }
    end
    let(:expected_message) do
      { chat_id: 4,
        media: [
          { type: 'photo', media: File.open(media.first), caption: message.text },
          { type: 'photo', media: File.open(media.second), caption: '' }
        ],
        parse_mode: :HTML }
    end

    it 'sanity-check: telegram bot is not nil' do
      expect(organization.telegram_bot).to be_truthy
    end

    it 'sends the message with TelegramBot' do
      expect(organization.telegram_bot).to receive(:send_media_group).with(expected_message)

      subject.call
    end

    context 'successful sent' do
      let(:external_id) { successful_response.with_indifferent_access[:result].first[:message_id].to_s }

      it 'marks the message as sent' do
        expect { subject.call }.to change { message.reload.sent_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it "saves the message's external id" do
        expect { subject.call }.to change { message.reload.external_id }.from(nil).to(external_id)
      end
    end

    describe 'Unknown organization' do
      let(:organization_id) { 564_321 }

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(ActiveRecord::RecordNotFound)

        subject.call
      end
    end

    describe 'Unknown contributor' do
      let(:contributor_id) { 564_321 }

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(ActiveRecord::RecordNotFound)

        subject.call
      end

      context 'not part of organization' do
        let(:contributor_id) { create(:contributor).id }

        it 'reports the error' do
          expect(Sentry).to receive(:capture_exception).with(ActiveRecord::RecordNotFound)

          subject.call
        end
      end
    end
  end
end
