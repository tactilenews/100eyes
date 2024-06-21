# frozen_string_literal: true

RSpec.shared_examples 'a resubscribe failure' do |adapter|
  let!(:request) { create(:request, organization: organization) }
  let(:failure_message) { I18n.t('adapter.shared.resubscribe.failure') }
  let(:resubscribe_error) do
    ResubscribeContributorJob::ResubscribeError.new(resubscribe_error_text)
  end
  let(:resubscribe_error_text) do
    "Contributor #{contributor.name} has been deactivated by #{deactivated_by} and has tried to re-subscribe"
  end
  let(:deactivated_by) { (contributor.deactivated_by_user&.name || 'an admin').to_s }

  it { is_expected.not_to change(Message, :count) }
  it { is_expected.not_to(change { contributor.reload.unsubscribed_at }) }
  it 'reports an error' do
    expect(Sentry).to receive(:capture_exception).with(resubscribe_error)
    subject.call
  end
  it {
    is_expected.to(have_enqueued_job(adapter).on_queue('default').with do |params|
      expect(params[:organization_id]).to eq(organization.id)
      if adapter.eql?(WhatsAppAdapter::Outbound::ThreeSixtyDialogText)
        expect(params[:payload][:to]).to eq(contributor.whats_app_phone_number.split('+').last)
        expect(params[:payload][:text][:body]).to eq(failure_message)
      else
        expect(params[:contributor_id]).to eq(contributor.id)
        expect(params[:text]).to match(failure_message)
      end
    end)
  }
end
