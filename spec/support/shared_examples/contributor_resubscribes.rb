# frozen_string_literal: true

RSpec.shared_examples 'a Contributor resubscribes' do |adapter|
  let!(:request) { create(:request) }
  let!(:admin) { create_list(:user, 2, admin: true) }
  let!(:non_admin_user) { create(:user) }
  let(:welcome_message) do
    Setting.onboarding_success_text
  end

  it { is_expected.not_to change(Message, :count) }
  it { is_expected.to change { contributor.reload.unsubscribed_at }.from(kind_of(ActiveSupport::TimeWithZone)).to(nil) }
  it {
    is_expected.to(have_enqueued_job(adapter).on_queue('default').with do |params|
      expect(params[:contributor_id]).to eq(contributor.id)
      expect(params[:text]).to match(welcome_message)
    end)
  }
  it_behaves_like 'an ActivityNotification', 'ContributorSubscribed'
  it 'enqueues a job to inform admin' do
    expect { subject.call }.to have_enqueued_job.on_queue('default').with(
      'PostmarkAdapter::Outbound',
      'contributor_resubscribed_email',
      'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
      {
        params: { admin: an_instance_of(User), contributor: contributor },
        args: []
      }
    ).exactly(2).times
  end
end
