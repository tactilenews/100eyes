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
      render_type: :media,
      file_name: message.files.first.attachment.blob.filename.to_s,
      caption: message.text
    }
  end
  let(:message_id) { SecureRandom.alphanumeric(16) }
  let(:threema_lookup_double) { instance_double(Threema::Lookup) }

  describe '#perform' do
    before do
      message.reload
      allow(ThreemaAdapter::Outbound::File).to receive(:threema_instance).and_return(threema_double)
      allow(Threema::Lookup).to receive(:new).and_call_original
      allow(Threema::Lookup).to receive(:new).with({ threema: threema_double }).and_return(threema_lookup_double)
      allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
    end
    subject do
      lambda {
        adapter.perform(contributor_id: message.recipient.id,
                        file_path: file_path,
                        file_name: message.files.first.attachment.blob.filename.to_s,
                        caption: message.text,
                        render_type: :media)
      }
    end

    it 'sends the file' do
      expect(threema_double).to receive(:send).with(expected_params)

      subject.call
    end

    context 'when a message is passed in' do
      subject do
        lambda {
          adapter.perform(contributor_id: message.recipient.id,
                          file_path: file_path,
                          file_name: message.files.first.attachment.blob.filename.to_s,
                          caption: message.text,
                          render_type: :media,
                          message: message)
        }
      end

      before do
        allow(threema_double).to receive(:send).with(expected_params).and_return(message_id)
      end

      it "saves the returned message id to the message's external_id" do
        expect { subject.call }.to change { message.reload.external_id }.from(nil).to(message_id)
      end
    end
  end
end
