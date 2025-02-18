# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound::File do
  let(:adapter) { described_class.new }
  let(:threema_double) { instance_double(Threema) }
  let(:threema_id) { 'V5EA564T' }
  let(:organization) do
    create(:organization, threemarb_api_identity: '*100EYES', threemarb_api_secret: 'valid_secret', threemarb_private: 'valid_private')
  end
  let(:contributor) { create(:contributor, :skip_validations, threema_id: threema_id, email: nil, organization: organization) }
  let(:contributor_id) { contributor.id }
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
      allow(Threema).to receive(:new).and_return(threema_double)
      allow(Threema::Lookup).to receive(:new).and_call_original
      allow(Threema::Lookup).to receive(:new).with({ threema: threema_double }).and_return(threema_lookup_double)
      allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
    end
    subject do
      lambda {
        adapter.perform(contributor_id: contributor_id,
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
          adapter.perform(contributor_id: contributor_id,
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

      it 'saves the current time as sent_at' do
        expect { subject.call }.to change { message.reload.sent_at }.from(nil).to be_within(1.second).of(Time.current)
      end
    end

    describe 'Unknown contributor' do
      let(:contributor_id) { 564_321 }

      it 'throws an error' do
        expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'Invalid threema ID' do
      let(:invalid_threema_error) { RuntimeError.new("Can't find public key for Threema ID #{threema_id}") }
      before { allow(threema_double).to receive(:send).with(expected_params).and_raise(invalid_threema_error) }

      it 'enqueues a job to mark inactive contributor inactive' do
        expect { subject.call }.to have_enqueued_job(MarkInactiveContributorInactiveJob).with(
          organization_id: organization.id,
          contributor_id: contributor.id
        )
      end

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(invalid_threema_error)

        subject.call
      end
    end
  end
end
