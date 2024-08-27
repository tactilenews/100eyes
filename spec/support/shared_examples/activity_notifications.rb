# frozen_string_literal: true

RSpec.shared_examples 'an ActivityNotification' do |event_type, count|
  context 'creates activity notifications' do
    it " of type #{event_type}" do
      expect { run_action(subject) }.to change(ActivityNotification.where(type: event_type), :count).by(count)
    end

    it 'for each user' do
      run_action(subject)
      recipient_ids = ActivityNotification.where(type: event_type).pluck(:recipient_id).uniq.sort
      user_ids = organization.users.pluck(:id)
      admin_ids = User.admin.pluck(:id)
      all_org_user_plus_admin = (user_ids + admin_ids).sort
      expect(recipient_ids).to eq(all_org_user_plus_admin)
    end
  end

  def run_action(subject)
    if subject.respond_to? :call
      subject.call
    else
      subject
    end
  end
end
