# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Requests', type: :request do
  let(:organization) { create(:organization) }

  describe 'GET /{organization_id}/requests' do
    it_behaves_like 'unauthenticated' do
      before { get organization_requests_path(organization) }
    end

    it_behaves_like 'protected' do
      before { get organization_requests_path(organization, as: create(:user)) }
    end

    context 'authenticated and authorized' do
      subject { -> { get organization_requests_path(organization, as: user), params: params } }

      let(:user) { create(:user, organizations: [organization]) }
      let(:params) { {} }

      before do
        create(:request, title: 'I belong to the organization', organization: organization)
        create(:request, title: 'I do too!', organization: organization)
        create(:request, title: 'Planned for the future', schedule_send_for: 1.day.from_now, broadcasted_at: nil,
                         organization: organization)
        create(:request, title: 'Also planned, but from another organization', schedule_send_for: 1.hour.from_now, broadcasted_at: nil)
        create(:request, title: 'From another organization', organization: create(:organization))
        subject.call
      end

      it 'should be successful' do
        subject.call
        expect(response).to be_successful
      end

      context 'no params' do
        it 'displays only sent messages' do
          expect(page).to have_content('I belong to the organization')
          expect(page).to have_content('I do too!')
          expect(page).not_to have_content('Planned for the future')
        end

        it 'display only requests from the organization' do
          expect(page).to have_content('Gestellt 2')
          expect(page).to have_content('Geplant 1')
          expect(page).to have_content('I belong to the organization')
          expect(page).to have_content('I do too!')
          expect(page).not_to have_content('From another organization')
        end
      end

      context 'sent filter param' do
        let(:params) { { filter: :sent } }

        it 'displays only sent messages' do
          expect(page).to have_content('I belong to the organization')
          expect(page).to have_content('I do too!')
          expect(page).not_to have_content('Planned for the future')
        end
      end

      context 'planned filter param' do
        let(:params) { { filter: :planned } }

        it 'displays only sent messages' do
          expect(page).not_to have_content('I belong to the organization')
          expect(page).not_to have_content('I do too!')
          expect(page).to have_content('Planned for the future')
        end

        it 'display only requests from the organization' do
          expect(page).to have_content('Gestellt 2')
          expect(page).to have_content('Geplant 1')
          expect(page).to have_content('Planned for the future')
          expect(page).not_to have_content('Also planned, but from another organization')
        end
      end
    end
  end

  describe 'GET /{organization_id}/requests' do
    let(:request) { create(:request, organization: organization) }

    it_behaves_like 'unauthenticated' do
      before { get organization_request_path(organization, request) }
    end

    context 'user not part of organization' do
      it_behaves_like 'protected' do
        before { get organization_request_path(organization, request, as: create(:user)) }
      end
    end

    context 'authenticated and authorized' do
      subject { -> { get organization_request_path(organization, request, as: user) } }

      let(:user) { create(:user, organizations: [organization]) }

      context 'request not part of organization' do
        let(:request) { create(:request, organization: create(:organization)) }

        it_behaves_like 'protected' do
          before { get organization_request_path(organization, request, as: user) }
        end
      end

      context 'request is part of organization' do
        it 'should be successful' do
          subject.call
          expect(response).to be_successful
        end
      end
    end
  end

  describe 'POST /{organization_id}/requests' do
    subject { -> { post organization_requests_path(organization, as: user), params: params } }
    
    let(:params) { { request: { title: 'Example Question', text: 'How do you do?', hints: ['confidential'] } } }
    let(:user) { create(:user, organizations: [organization]) }
    
    before do
      allow(Request).to receive(:broadcast!).and_call_original # is stubbed for every other test
    end

    it_behaves_like 'unauthenticated' do
      before { post organization_requests_path(organization), params: params }
    end

    context 'user not part of organization' do
      it_behaves_like 'protected' do
        before { post organization_requests_path(organization, as: create(:user)), params: params }
      end
    end

    it { should change { Request.count }.from(0).to(1) }

    it 'redirects to requests#show' do
      subject.call
      request = organization.requests.first
      expect(response).to redirect_to organization_request_path(organization, request)
    end

    it 'shows success notification' do
      subject.call
      expect(flash[:success]).to eq('Deine Frage wurde erfolgreich an 0 Mitglieder in der Community gesendet')
    end

    describe 'without hints param' do
      let(:params) { { request: {  title: 'Example Question', text: 'How do you do?' } } }
      it { should_not raise_error }
    end

    describe 'without contributors' do
      it { should_not raise_error }
    end

    describe 'with contributors' do
      before do
        create_list(:contributor, 2, organization: organization)
        create(:contributor, organization: create(:organization))
        subject.call
      end

      context 'with image file(s)' do
        let(:params) do
          { request: { title: 'Message with files', text: 'Did you get this image?', files: [fixture_file_upload('profile_picture.jpg')] } }
        end

        describe 'an image file' do
          it 'redirects to requests#show' do
            request = organization.requests.first

            expect(response).to redirect_to organization_request_path(organization, request)
          end

          it 'shows success notification' do
            expect(flash[:success]).to eq('Deine Frage wurde erfolgreich an 2 Mitglieder in der Community gesendet')
          end
        end

        describe 'multiple image files' do
          let(:params) do
            { request: { title: 'Message with files', text: 'Did you get this image?',
                         files: [fixture_file_upload('profile_picture.jpg'), fixture_file_upload('example-image.png')] } }
          end

          it 'redirects to requests#show' do
            request = Request.first
            expect(response).to redirect_to organization_request_path(organization, request)
          end

          it 'shows success notification' do
            expect(flash[:success]).to eq('Deine Frage wurde erfolgreich an 2 Mitglieder in der Community gesendet')
          end
        end

        describe 'with no text' do
          before { params[:request][:text] = '' }

          it 'redirects to requests#show' do
            request = Request.first
            expect(response).to redirect_to organization_request_path(organization, request)
          end

          it 'shows success notification' do
            expect(flash[:success]).to eq('Deine Frage wurde erfolgreich an 2 Mitglieder in der Community gesendet')
          end
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

    let(:user) { create(:user, organizations: [organization]) }

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
    let(:request) { create(:request, organization: organization) }
    let!(:older_message) { create(:message, request_id: request.id, created_at: 2.minutes.ago) }
    let(:params) { { last_updated_at: 1.minute.ago } }
    let(:user) { create(:user, organizations: [organization]) }

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
