# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Questions', telegram_bot: :rails do
  describe 'POST /questions' do
    subject { -> { post questions_path, params: { question: 'How do you do?' } } }
    describe 'without users' do
      it { should_not raise_error }
    end

    describe 'given a user with an email' do
      before(:each) { User.create!(email: 'user@example.org') }
      it { should change { ActionMailer::Base.deliveries.count }.from(0).to(1) }
      it { should_not respond_with_message }
    end

    describe 'given a user with a telegram_chat_id' do
      let(:chat_id) { 4711 }
      before(:each) { User.create!(telegram_chat_id: 4711) }
      it { should respond_with_message 'How do you do?' }
      it {
        pending('Once we have users with email addresses, skip them')
        should_not(change { ActionMailer::Base.deliveries.count })
      }
    end
  end
end
