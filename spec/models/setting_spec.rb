# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Setting, type: :model do
  let(:uploaded_file) { fixture_file_upload('profile_picture.jpg') }
  let(:blob) { ActiveStorage::Blob.create_and_upload!(io: uploaded_file, filename: uploaded_file.original_filename) }
  subject { Setting }

  %i[onboarding_logo onboarding_hero].each do |getter|
    setter = "#{getter}="
    blob_id_getter = "#{getter}_blob_id"
    blob_id_setter = "#{getter}_blob_id="

    describe getter do
      subject { Setting.send(getter) }
      it { should be_nil }
      context 'if there was a blob uploaded' do
        before { Setting.send(blob_id_setter, blob.id) }
        it { should be_a(ActiveStorage::Blob) }
      end
    end

    describe setter do
      subject { -> { Setting.send(setter, blob) } }
      it "sets #{getter}" do
        will change { Setting.send(getter) }.from(nil).to(blob)
      end

      it "changes #{blob_id_getter}" do
        will change { Setting.send(blob_id_getter) }.from(nil).to(blob.id)
      end

      context 'any existing blob' do
        let(:another_uploaded_file) { fixture_file_upload('example-image.png') }
        let(:another_blob) do
          ActiveStorage::Blob.create_and_upload!(io: another_uploaded_file, filename: another_uploaded_file.original_filename)
        end
        before { Setting.send(blob_id_setter, another_blob.id) }

        it 'gets deleted' do
          will enqueue_job(ActiveStorage::PurgeJob)
        end

        it "changes #{getter}" do
          will change { Setting.send(getter) }.from(another_blob).to(blob)
        end

        it "overwrites #{blob_id_getter}" do
          will change { Setting.send(blob_id_getter) }.from(another_blob.id).to(blob.id)
        end
      end
    end
  end
end
