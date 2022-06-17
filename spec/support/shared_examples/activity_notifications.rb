# frozen_string_literal: true

RSpec.shared_examples 'activity_notifications' do
  let!(:users) { create_list(:user, 5) }

  it 'of type OnboardingCompleted' do
    expect { subject.call }.to change(ActivityNotification.where(type: 'OnboardingCompleted'), :count).by(User.count)
  end

  it 'for each user' do
    subject.call
    recipient_ids = ActivityNotification.where(type: 'OnboardingCompleted').pluck(:recipient_id)
    user_ids = User.pluck(:id)
    expect(recipient_ids).to eq(user_ids)
  end
end
