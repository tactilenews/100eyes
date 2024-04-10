# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Setting, type: :model do
  subject { described_class }

  let(:uploaded_file) { fixture_file_upload('profile_picture.jpg') }
  let(:blob) { ActiveStorage::Blob.create_and_upload!(io: uploaded_file, filename: uploaded_file.original_filename) }

  %i[onboarding_logo onboarding_hero].each do |getter|
    setter = "#{getter}="
    blob_id_getter = "#{getter}_blob_id"
    blob_id_setter = "#{getter}_blob_id="

    describe getter do
      subject { described_class.send(getter) }

      it { is_expected.to be_nil }

      context 'if there was a blob uploaded' do
        before { described_class.send(blob_id_setter, blob.id) }

        it { is_expected.to be_a(ActiveStorage::Blob) }
      end
    end

    describe setter do
      subject { -> { described_class.send(setter, blob) } }

      it "sets #{getter}" do
        will change { described_class.send(getter) }.from(nil).to(blob)
      end

      it "changes #{blob_id_getter}" do
        will change { described_class.send(blob_id_getter) }.from(nil).to(blob.id)
      end

      context 'any existing blob' do
        let(:another_uploaded_file) { fixture_file_upload('example-image.png') }
        let(:another_blob) do
          ActiveStorage::Blob.create_and_upload!(io: another_uploaded_file, filename: another_uploaded_file.original_filename)
        end

        before { described_class.send(blob_id_setter, another_blob.id) }

        it 'gets deleted' do
          will enqueue_job(ActiveStorage::PurgeJob)
        end

        it "changes #{getter}" do
          will change { described_class.send(getter) }.from(another_blob).to(blob)
        end

        it "overwrites #{blob_id_getter}" do
          will change { described_class.send(blob_id_getter) }.from(another_blob.id).to(blob.id)
        end
      end
    end
  end

  context '::onboarding_success_*' do
    let!(:users) { create_list(:user, 2) }
    let!(:admin) { create_list(:user, 3, admin: true) }
    let(:param) { 'new value' }

    describe 'onboarding_success_heading' do
      let(:default_value) { File.read(File.join('config', 'locales', 'onboarding', 'success_heading.txt')) }

      context 'getter' do
        subject { described_class.send(method) }

        let(:method) { :onboarding_success_heading }

        it { is_expected.to eq(default_value) }
      end

      context 'setter' do
        subject { described_class.send(method, param) }

        let(:method) { 'onboarding_success_heading=' }

        context 'setter other than onboarding_success_*' do
          let(:method) { 'project_name=' }

          it 'does not notify admin' do
            expect { subject }.not_to have_enqueued_job
          end
        end

        it 'updates the value' do
          expect { subject }.to change(described_class, :onboarding_success_heading).from(default_value).to(param)
        end

        it 'sends an email to all admin that the value was updated' do
          expect { subject }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'welcome_message_updated_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: an_instance_of(User) },
              args: []
            }
          ).exactly(3).times
        end
      end
    end

    describe 'onboarding_success_text' do
      let(:default_value) { File.read(File.join('config', 'locales', 'onboarding', 'success_text.txt')) }

      context 'getter' do
        subject { described_class.send(method) }

        let(:method) { :onboarding_success_text }

        it { is_expected.to eq(default_value) }
      end

      context 'setter' do
        subject { described_class.send(method, param) }

        let(:method) { 'onboarding_success_text=' }

        it 'updates the value' do
          expect { subject }.to change(described_class, :onboarding_success_text).from(default_value).to(param)
        end

        it 'sends an email to all admin that the value was updated' do
          expect { subject }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'welcome_message_updated_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: an_instance_of(User) },
              args: []
            }
          ).exactly(3).times
        end
      end
    end
  end
end
