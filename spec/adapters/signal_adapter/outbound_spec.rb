# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SignalAdapter::Outbound do
  let(:adapter) { described_class.new }
  let(:message) { create(:message, text: 'Forgot to ask: How are you?', broadcasted: true, recipient: contributor) }
  let(:contributor) { create(:contributor, email: nil) }
  let(:expected_job_args) do
    { recipient: contributor, text: [Setting.onboarding_success_heading, Setting.onboarding_success_text].join("\n") }
  end

  describe '::send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor) } }
    before { message } # we don't count the extra ::send here

    it { should_not enqueue_job(described_class::Text) }

    context 'contributor has a phone number' do
      let(:onboarding_completed_at) { nil }
      let(:contributor) do
        create(
          :contributor,
          signal_phone_number: '+491511234567',
          signal_onboarding_completed_at: onboarding_completed_at,
          email: nil
        )
      end

      it { should_not enqueue_job(described_class::Text) }

      context 'and has completed onboarding' do
        let(:onboarding_completed_at) { Time.zone.now }
        it { should enqueue_job(described_class::Text).with(expected_job_args) }
      end
    end
  end

  describe '::send!' do
    subject { -> { described_class.send!(message) } }
    before { message } # we don't count the extra ::send here
    it { should_not enqueue_job(described_class::Text) }

    describe 'contributor has a phone number' do
      let(:onboarding_completed_at) { nil }

      let(:contributor) do
        create(
          :contributor,
          email: nil,
          signal_phone_number: '+491511234567',
          signal_onboarding_completed_at: onboarding_completed_at
        )
      end

      it { should_not enqueue_job(described_class::Text) }

      context 'and has completed onboarding' do
        let(:onboarding_completed_at) { Time.zone.now }
        it { should enqueue_job(described_class::Text) }
      end
    end
  end
end
