# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SignalAdapter::Outbound do
  let(:adapter) { described_class.new }
  let(:message) { create(:message, text: 'Forgot to ask: How are you?', broadcasted: true, recipient: contributor) }
  let(:contributor) { create(:contributor, email: nil) }
  let(:expected_job_args) do
    { contributor_id: contributor.id, text: [Setting.onboarding_success_heading, Setting.onboarding_success_text].join("\n") }
  end
  let(:onboarding_completed_at) { nil }

  describe '::send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor) } }
    before { message } # we don't count the extra ::send here

    it { should_not enqueue_job(described_class::Text) }

    context 'contributor has a phone number' do
      let(:contributor) do
        create(
          :contributor,
          signal_phone_number: '+491511234567',
          signal_onboarding_completed_at: onboarding_completed_at,
          email: nil
        )
      end

      context 'but has not completed onboarding' do
        it 'does not enqueue the job to send the welcome message' do
          expect { subject.call }.not_to enqueue_job(described_class::Text)
        end
      end

      context 'has completed onboarding' do
        let(:onboarding_completed_at) { 1.minute.ago }

        it 'enqueus the job to send out the welcome message' do
          expect { subject.call }.to enqueue_job(described_class::Text).with(expected_job_args)
        end
      end
    end

    context 'contributor has a uuid' do
      let(:contributor) do
        create(
          :contributor,
          signal_uuid: 'valid_uuid',
          signal_onboarding_completed_at: onboarding_completed_at,
          email: nil
        )
      end

      context 'but has not completed onboarding' do
        it 'does not enqueue the job to send the welcome message' do
          expect { subject.call }.not_to enqueue_job(described_class::Text)
        end
      end

      context 'has completed onboarding' do
        let(:onboarding_completed_at) { 1.minute.ago }

        it 'enqueus the job to send out the welcome message' do
          expect { subject.call }.to enqueue_job(described_class::Text).with(expected_job_args)
        end
      end
    end
  end

  describe '::send!' do
    subject { -> { described_class.send!(message) } }

    let(:expected_job_args) do
      { contributor_id: contributor.id, text: message.text }
    end
    before { message } # we don't count the extra ::send here

    it { should_not enqueue_job(described_class::Text) }

    describe 'contributor has a phone number' do
      let(:contributor) do
        create(
          :contributor,
          email: nil,
          signal_phone_number: '+491511234567',
          signal_onboarding_completed_at: onboarding_completed_at
        )
      end

      context 'but has not completed onboarding' do
        it 'does not enqueue the job to send the welcome message' do
          expect { subject.call }.not_to enqueue_job(described_class::Text)
        end
      end

      context 'has completed onboarding' do
        let(:onboarding_completed_at) { 1.minute.ago }

        it 'enqueus the job to send out the welcome message' do
          expect { subject.call }.to enqueue_job(described_class::Text).with(expected_job_args)
        end
      end
    end

    describe 'contributor has a uuid' do
      let(:contributor) do
        create(
          :contributor,
          email: nil,
          signal_uuid: 'valid_uuid',
          signal_onboarding_completed_at: onboarding_completed_at
        )
      end

      context 'but has not completed onboarding' do
        it 'does not enqueue the job to send the welcome message' do
          expect { subject.call }.not_to enqueue_job(described_class::Text)
        end
      end

      context 'has completed onboarding' do
        let(:onboarding_completed_at) { 1.minute.ago }

        it 'enqueus the job to send out the welcome message' do
          expect { subject.call }.to enqueue_job(described_class::Text).with(expected_job_args)
        end
      end
    end
  end
end
