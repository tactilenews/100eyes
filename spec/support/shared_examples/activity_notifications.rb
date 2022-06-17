# frozen_string_literal: true

RSpec.shared_examples 'activity_notifications' do |event_type|
  let!(:users) { create_list(:user, 5) }

  it 'of type OnboardingCompleted' do
    expect { run_action(subject) }.to change(ActivityNotification.where(type: event_type), :count).by(User.count)
  end

  it 'for each user' do
    run_action(subject)
    recipient_ids = ActivityNotification.where(type: event_type).pluck(:recipient_id)
    user_ids = User.pluck(:id)
    expect(recipient_ids).to eq(user_ids)
  end

  def run_action(subject)
    if subject.respond_to? :call
      subject.call
    else
      subject
    end
  end
end
