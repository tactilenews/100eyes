# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound do
  let(:adapter) { described_class.new }
  let(:threema_id) { 'V5EA564T' }
  let(:contributor) { create(:contributor, threema_id: threema_id, email: nil) }
  let(:message) { create(:message, recipient: contributor) }
  let(:onboarding_success_heading_record) { Setting.new(var: :onboarding_success_heading) }
  let(:onboarding_success_text_record) { Setting.new(var: :onboarding_success_text) }

  before do
    allow(Setting).to receive(:find_by).with(var: :onboarding_success_heading).and_return(onboarding_success_heading_record)
    allow(onboarding_success_heading_record).to receive(:send)
      .with("value_#{I18n.locale}".to_sym).and_return(" \n text with leading and trailing whitespace \t \n ")
    allow(Setting).to receive(:find_by).with(var: :onboarding_success_text).and_return(onboarding_success_text_record)
    allow(onboarding_success_text_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return("\nSuccess text.\n")
  end

  describe '::send!' do
    before { message } # we don't count the extra ::send here

    subject { -> { described_class.send!(message) } }

    it { should enqueue_job(described_class) }

    context 'contributor has no threema_id' do
      let(:contributor) { create(:contributor, threema_id: nil, email: nil) }
      it { should_not enqueue_job(described_class) }
    end
  end

  describe '::send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor) } }

    it { should enqueue_job(described_class) }

    context 'contributor has no threema_id' do
      let(:contributor) { create(:contributor, threema_id: nil, email: nil) }
      it { should_not enqueue_job(described_class) }
    end
  end

  describe '#perform' do
    subject { -> { adapter.perform(text: message.text, recipient: message.recipient) } }

    it 'sends the message' do
      expect_any_instance_of(Threema).to receive(:send).with(type: :text, threema_id: 'V5EA564T', text: message.text)
      subject.call
    end

    context 'with lowercase Threema ID' do
      let(:threema_id) { 'v5ea564t' }

      it 'converts ID to uppercase' do
        expect_any_instance_of(Threema).to receive(:send).with(type: :text, threema_id: 'V5EA564T', text: message.text)
        subject.call
      end
    end
  end

  describe '#welcome_message' do
    subject { described_class.welcome_message }

    it 'strips whitespace to not break basic formatting' do
      is_expected.to eq("*text with leading and trailing whitespace*\n\nSuccess text.\n")
    end
  end
end
