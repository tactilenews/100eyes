# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound do
  let(:threema_id) { 'V5EA564T' }
  let(:organization) { create(:organization, threemarb_api_identity: '*100EYES') }
  let(:contributor) { create(:contributor, :skip_validations, threema_id: threema_id, email: nil, organization: organization) }
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

    let(:welcome_message) do
      ["*#{organization.onboarding_success_heading.strip}*", organization.onboarding_success_text].join("\n")
    end

    it 'queues the job to send the welcome message' do
      expect do
        subject.call
      end.to have_enqueued_job(ThreemaAdapter::Outbound::Text).with(contributor_id: contributor.id,
                                                                    text: welcome_message)
    end

    context 'contributor has no threema_id' do
      let(:contributor) { create(:contributor, threema_id: nil, email: nil) }
      it { should_not enqueue_job(described_class) }
    end
  end
end
