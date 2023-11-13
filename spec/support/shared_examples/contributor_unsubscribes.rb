# frozen_string_literal: true

RSpec.shared_examples 'a Contributor unsubscribes' do |adapter|
  let!(:request) { create(:request) }
  let!(:admin) { create_list(:user, 2, admin: true) }
  let!(:non_admin_user) { create(:user) }
  let(:unsubscribe_successful_message) do
    [I18n.t('adapter.shared.unsubscribe.successful')].join("\n\n")
  end

  it { is_expected.not_to change(Message, :count) }
  it { is_expected.to change { contributor.reload.unsubscribed_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone)) }
  it {
    is_expected.to(have_enqueued_job(adapter).on_queue('default').with do |params|
      expect(params[:contributor_id]).to eq(contributor.id)
      expect(params[:text]).to match(unsubscribe_successful_message)
    end)
  }
  it_behaves_like 'an ActivityNotification', 'ContributorMarkedInactive'
  it 'enqueues a job to inform admin' do
    expect { subject.call }.to have_enqueued_job.on_queue('default').with(
      'PostmarkAdapter::Outbound',
      'contributor_marked_as_inactive_email',
      'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
      {
        params: { admin: an_instance_of(User), contributor: contributor },
        args: []
      }
    ).exactly(2).times
  end
end
