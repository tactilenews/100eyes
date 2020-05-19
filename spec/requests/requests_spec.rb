# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Requests', telegram_bot: :rails do
  describe 'POST /requests' do
    subject { -> { post requests_path, params: params } }
    let(:params) { { title: 'Example Question', text: 'How do you do?', hints: ['confidential'] } }

    it { should change { Request.count }.from(0).to(1) }

    describe 'without hints param' do
      let(:params) { { title: 'Example Question', text: 'How do you do?' } }
      it { should_not raise_error }
    end

    describe 'without users' do
      it { should_not raise_error }
    end

    describe 'given a user with an email address' do
      before(:each) { User.create!(email: 'user@example.org', telegram_chat_id: nil) }
      it {
        should have_enqueued_job.on_queue('mailers').with(
          'QuestionMailer',
          'new_question_email',
          'deliver_now',
          {
            params: {
              question: "Hallo, die Redaktion hat eine neue Frage an dich:\n\nHow do you do?\n\nTextbaustein für vertrauliche Informationen\n\nVielen Dank für deine Hilfe bei unserer Recherche!",
              to: 'user@example.org'
            },
            args: []
          }
        )
      }

      it { should_not respond_with_message }
    end

    describe 'given a user with a telegram_chat_id' do
      let(:chat_id) { 4711 }
      before(:each) { User.create!(telegram_chat_id: 4711, email: nil) }
      it { should respond_with_message "Hallo, die Redaktion hat eine neue Frage an dich:\n\nHow do you do?\n\nTextbaustein für vertrauliche Informationen\n\nVielen Dank für deine Hilfe bei unserer Recherche!" }
      it { should_not have_enqueued_job.on_queue('mailers') }
    end
  end
end
