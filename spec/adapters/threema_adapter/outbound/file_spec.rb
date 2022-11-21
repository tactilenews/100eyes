# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound::File do
  let(:adapter) { described_class.new }
  let(:threema_double) { instance_double(Threema) }
  let(:threema_id) { 'V5EA564T' }
  let(:contributor) do
    build(:contributor, threema_id: threema_id, email: nil).tap { |contributor| contributor.save(validate: false) }
  end
  let(:message) { create(:message, :with_file, recipient: contributor) }
  let(:file_path) { ActiveStorage::Blob.service.path_for(message.files.first.attachment.blob.key) }
  let(:expected_params) do
    {
      type: :file,
      threema_id: threema_id,
      file: file_path,
      thumbnail: file_path,
      file_name: message.files.first.attachment.blob.filename.to_s,
      caption: message.text
    }
  end

  describe '#perform' do
    before do
      message.reload
      allow(Threema).to receive(:new).and_return(threema_double)
    end
    subject do
      lambda {
        adapter.perform(recipient: message.recipient,
                        file_path: file_path,
                        file_name: message.files.first.attachment.blob.filename.to_s,
                        caption: message.text,
                        thumbnail: file_path)
      }
    end

    it 'sends the file' do
      expect(threema_double).to receive(:send).with(expected_params)

      subject.call
    end
  end
end
