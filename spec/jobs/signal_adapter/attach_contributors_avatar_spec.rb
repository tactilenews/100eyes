# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalAdapter::AttachContributorsAvatar do
  describe '#perform_later(contributor)' do
    subject { -> { described_class.new.perform(contributor) } }
    let(:contributor) { create(:contributor, signal_phone_number: '+491212343434') }

    context 'with avatar on file system' do
      let(:avatar) { file_fixture('profile-+491212343434') }
      before do
        allow(File).to receive(:file?).with("/app/signal-cli-config/avatars/profile-#{contributor.signal_phone_number}").and_return(true)
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open)
          .with('/app/signal-cli-config/avatars/profile-+491212343434')
          .and_return(avatar.open)
      end

      it 'attaches the avatar to the contributor based on its phone number' do
        expect { subject.call }.to change(ActiveStorage::Attachment, :count).by(1)
      end
    end

    context 'no avatar on file' do
      it 'does not attach an avatar' do
        expect { subject.call }.not_to change(ActiveStorage::Attachment, :count)
      end
    end
  end
end
