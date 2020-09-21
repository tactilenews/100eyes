# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Requests', telegram_bot: :rails do
  describe 'POST /requests' do
    before(:each) { allow(Request).to receive(:broadcast!).and_call_original } # is stubbed for every other test
    subject { -> { post requests_path, params: params, headers: auth_headers } }
    let(:params) { { request: { title: 'Example Question', text: 'How do you do?', hints: ['confidential'] } } }

    it { should change { Request.count }.from(0).to(1) }

    it 'redirects to requests#show' do
      response = subject.call
      request = Request.last
      expect(response).to redirect_to request
    end

    it 'shows success notification' do
      subject.call
      expect(flash[:success]).not_to be_empty
    end

    describe 'without hints param' do
      let(:params) { { request: {  title: 'Example Question', text: 'How do you do?' } } }
      it { should_not raise_error }
    end

    describe 'without users' do
      it { should_not raise_error }
    end

    describe 'given a user with an email address' do
      before(:each) { User.create!(email: 'user@example.org', telegram_chat_id: nil) }
      it {
        should have_enqueued_job.on_queue('mailers').with(
          'MessageMailer',
          'new_message_email',
          'deliver_now',
          {
            params: {
              message: [
                'How do you do?',
                I18n.t('request.hints.confidential.text')
              ].join("\n\n"),
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
      let(:expected_message) do
        [
          'How do you do?',
          I18n.t('request.hints.confidential.text')
        ].join("\n\n")
      end
      before(:each) { User.create!(telegram_chat_id: 4711, email: nil) }
      it { should respond_with_message expected_message }
      it { should_not have_enqueued_job.on_queue('mailers') }
    end
  end

  describe 'GET /notifications' do
    let(:request) { create(:request) }
    let!(:older_message) { create(:message, request_id: request.id, created_at: 2.minutes.ago) }
    let(:params) { { last_updated_at: 1.minute.ago } }

    subject { -> { get notifications_request_path(request), headers: auth_headers, params: params } }

    context 'No messages in last 1 minute' do
      it 'responds with message count 0' do
        expected = { message_count: 0 }.to_json
        subject.call
        expect(response.body).to eq(expected)
      end
    end

    context 'New messages in last 1 minute' do
      let!(:new_message) { create(:message, request_id: request.id, created_at: 30.seconds.ago) }

      it 'responds with message count' do
        expected = { message_count: 1 }.to_json
        subject.call
        expect(response.body).to eq(expected)
      end
    end
  end
end
