require 'rails_helper'

RSpec.describe 'Activity Notifications' do
  context 'with recent activity' do
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
    let(:otp_enabled) { true }
    let(:user) { create(:user, email: email, password: password, otp_enabled: otp_enabled) }
    let!(:activity_notification) { create(:activity_notification, recipient: user) }
    
    it "displays the activity notification on dashboard" do
      visit dashboard_path(as: user)
      expect(page).to have_text("Letzte Aktivität")
    end
  end
end
