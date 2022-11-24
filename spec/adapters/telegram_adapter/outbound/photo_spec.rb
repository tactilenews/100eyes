# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound::Photo do
  let(:adapter) { described_class.new }
  let(:contributor) { create(:contributor, telegram_id: 4) }
  let(:message) { create(:message, :with_file, text: 'Did you get my image file?', broadcasted: true, recipient: contributor) }
  let(:photos) { create_list(:file, 2, message: message) }
  let(:media) { photos.map { |photo| ActiveStorage::Blob.service.path_for(photo.attachment.blob.key) } }

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

    subject { adapter.perform(telegram_id: message.recipient.telegram_id, media: media, message: message) }
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
  end
end
