# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound do
  let(:adapter) { described_class.new }
  let(:threema_id) { 'V5EA564T' }
  let(:contributor) { create(:contributor, threema_id: threema_id, email: nil) }
  let(:message) { create(:message, recipient: contributor) }
  let(:threema) { instance_double(Threema) }
  let(:threema_lookup_double) { instance_double(Threema::Lookup) }
  before do
    allow(Threema).to receive(:new).and_return(threema)
    allow(Threema::Lookup).to receive(:new).and_return(threema_lookup_double)
    allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
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
    let(:threema_id) { 'v5ea564t' }

    it 'sends the message upcased' do
      expect(threema).to receive(:send).with(type: :text, threema_id: 'V5EA564T', text: message.text)
      subject.call
    end
  end

  describe '#welcome_message' do
    subject { described_class.welcome_message }

    it 'strips whitespace to not break basic formatting' do
      allow(Setting).to receive(:onboarding_success_heading).and_return(" \n text with leading and trailing whitespace \t \n ")
      allow(Setting).to receive(:onboarding_success_text).and_return("\nSuccess text.\n")
      is_expected.to eq("*text with leading and trailing whitespace*\n\nSuccess text.\n")
    end
  end
end
