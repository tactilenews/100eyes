# frozen_string_literal: true

RSpec.shared_examples 'activity_notifications' do |spec_type|
  let!(:users) { create_list(:user, 5) }

  it 'of type OnboardingCompleted' do
    expect { run_action(spec_type) }.to change(ActivityNotification.where(type: 'OnboardingCompleted'), :count).by(User.count)
  end

  it 'for each user' do
    run_action(spec_type)
    recipient_ids = ActivityNotification.where(type: 'OnboardingCompleted').pluck(:recipient_id)
    user_ids = User.pluck(:id)
    expect(recipient_ids).to eq(user_ids)
  end

  def run_action(spec_type)
    if spec_type == 'request'
      subject.call
    else
      subject
    end
  end
end
