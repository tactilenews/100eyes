# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound do
  let(:threema_id) { 'V5EA564T' }
  let(:contributor) do
    build(:contributor, threema_id: threema_id, email: nil).tap { |contributor| contributor.save(validate: false) }
  end
  let(:message) { create(:message, recipient: contributor) }

  describe '::send!' do
    before { message } # we don't count the extra ::send here

    subject { -> { described_class.send!(message) } }

    it { should enqueue_job(described_class::Text) }

    context 'contributor has no threema_id' do
      let(:contributor) { create(:contributor, threema_id: nil, email: nil) }
      it { should_not enqueue_job(described_class) }
    end

    context 'message has files attached' do
      before { message.reload }
      let(:message) { create(:message, :with_file, broadcasted: true, recipient: contributor) }

      it { should enqueue_job(described_class::File) }
    end
  end

  describe '::send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor) } }

    it { should enqueue_job(described_class::Text) }

    context 'contributor has no threema_id' do
      let(:contributor) { create(:contributor, threema_id: nil, email: nil) }
      it { should_not enqueue_job(described_class) }
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
