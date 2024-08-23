# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Requests', telegram_bot: :rails do
  let(:organization) { create(:organization) }

  describe 'POST /{organization_id}/requests' do
    before(:each) { allow(Request).to receive(:broadcast!).and_call_original } # is stubbed for every other test
    subject { -> { post organization_requests_path(organization, as: user), params: params } }
    let(:params) { { request: { title: 'Example Question', text: 'How do you do?', hints: ['confidential'] } } }
    let(:user) { create(:user) }

    it { should change { Request.count }.from(0).to(1) }

    it 'redirects to requests#show' do
      response = subject.call
      request = Request.last
      expect(response).to redirect_to organization_request_path(organization, request)
    end

    it 'shows success notification' do
      subject.call
      expect(flash[:success]).not_to be_empty
    end

    describe 'without hints param' do
      let(:params) { { request: {  title: 'Example Question', text: 'How do you do?' } } }
      it { should_not raise_error }
    end

    describe 'without contributors' do
      it { should_not raise_error }
    end

    context 'with image file(s)' do
      let(:params) do
        { request: { title: 'Message with files', text: 'Did you get this image?', files: [fixture_file_upload('profile_picture.jpg')] } }
      end

      describe 'an image file' do
        it 'redirects to requests#show' do
          response = subject.call
          request = Request.last
          expect(response).to redirect_to organization_request_path(organization, request)
        end

        it 'shows success notification' do
          subject.call
          expect(flash[:success]).not_to be_empty
        end
      end

      describe 'multiple image files' do
        let(:params) do
          { request: { title: 'Message with files', text: 'Did you get this image?',
                       files: [fixture_file_upload('profile_picture.jpg'), fixture_file_upload('example-image.png')] } }
        end

        it 'redirects to requests#show' do
          response = subject.call
          request = Request.last
          expect(response).to redirect_to organization_request_path(organization, request)
        end

        it 'shows success notification' do
          subject.call
          expect(flash[:success]).not_to be_empty
        end
      end

      describe 'with no text' do
        before { params[:request][:text] = '' }

        it 'redirects to requests#show' do
          response = subject.call
          request = Request.last
          expect(response).to redirect_to organization_request_path(organization, request)
        end

        it 'shows success notification' do
          subject.call
          expect(flash[:success]).not_to be_empty
        end
      end
    end

    context 'scheduled for future datetime' do
      let(:scheduled_datetime) { Time.current.tomorrow.beginning_of_hour }
      let(:params) do
        { request: { title: 'Scheduled request', text: 'Did you get this scheduled request?', schedule_send_for: scheduled_datetime } }
      end

      it 'redirects to requests#show' do
        response = subject.call
        expect(response).to redirect_to organization_requests_path(organization, filter: :planned)
      end

      it 'shows success notification' do
        subject.call
        request = Request.first
        expect(flash[:success]).to include(I18n.l(request.schedule_send_for, format: :long))
      end
    end
  end

  describe 'DELETE /{organization_id}/requests/:id' do
    subject do
      lambda {
        path = "/#{request.organization_id}/requests/#{request.id}?as=#{user.id}"
        delete path
      }
    end

    let(:user) { create(:user) }

    context 'broadcasted request' do
      let!(:request) { create(:request, organization: organization) }

      it 'does not delete the request' do
        expect { subject.call }.not_to change(Request, :count)
      end

      it 'redirects to requests path' do
        subject.call

        expect(response).to redirect_to organization_requests_path(organization)
      end

      it 'shows error message' do
        subject.call

        expect(flash[:error]).to eq(I18n.t('request.destroy.broadcasted_request_unallowed', request_title: request.title))
      end
    end

    context 'planned request' do
      let!(:request) { create(:request, organization: organization, broadcasted_at: nil, schedule_send_for: 1.day.from_now) }

      it 'deletes the request' do
        expect { subject.call }.to change(Request, :count).from(1).to(0)
      end

      it 'redirects to requests path with planned filter' do
        subject.call

        expect(response).to redirect_to organization_requests_path(organization, filter: :planned)
      end

      it 'shows a notice that it was successful' do
        subject.call

        expect(flash[:notice]).to eq(I18n.t('request.destroy.successful', request_title: request.title))
      end
    end
  end

  describe 'GET /{organization_id}/notifications' do
    let(:request) { create(:request) }
    let!(:older_message) { create(:message, request_id: request.id, created_at: 2.minutes.ago) }
    let(:params) { { last_updated_at: 1.minute.ago } }
    let(:user) { create(:user) }

    subject { -> { get notifications_organization_request_path(request.organization, request, as: user), params: params } }

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
