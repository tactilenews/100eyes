# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound::Photo do
  let(:adapter) { described_class.new }
  let(:contributor) { create(:contributor, telegram_id: 4) }
  let(:message) { create(:message, :with_file, text: 'Did you get my image file?', broadcasted: true, recipient: contributor) }
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

  before { allow(Telegram.bot).to receive(:send_media_group).and_return(successful_response) }

  describe '#perform' do
    subject { adapter.perform(contributor_id: message.recipient.id, media: media, message: message) }

    before do
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open)
        .with(media.first)
        .and_return(ActiveStorage::Blob.service.path_for(photos.first.attachment.blob.key))
      allow(File).to receive(:open)
        .with(media.second)
        .and_return(ActiveStorage::Blob.service.path_for(photos.second.attachment.blob.key))
    end

    let(:expected_message) do
      { chat_id: 4,
        media: [
          { type: 'photo', media: File.open(media.first), caption: message.text },
          { type: 'photo', media: File.open(media.second), caption: '' }
        ],
        parse_mode: :HTML }
    end

    it 'sends the message with TelegramBot' do
      expect(Telegram.bot).to receive(:send_media_group).with(expected_message)

      subject
    end

    context 'successful delivery' do
      let(:external_id) { successful_response.with_indifferent_access[:result].first[:message_id].to_s }

      it 'marks the message as received' do
        expect { subject }.to change { message.reload.received_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it "saves the message's external id" do
        expect { subject }.to change { message.reload.external_id }.from(nil).to(external_id)
      end
    end
  end
end
