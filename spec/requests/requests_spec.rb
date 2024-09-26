# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Requests', type: :request do
  let(:organization) { create(:organization) }

  describe 'GET /:organization_id/requests' do
    subject { -> { get organization_requests_path(organization, as: user), params: params } }

    let(:params) { {} }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'redirects to the sign in path' do
        subject.call
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, organizations: [create(:organization)]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, organizations: [organization]) }

      before do
        create(:request, title: 'I belong to the organization', organization: organization, broadcasted_at: 1.hour.ago)
        create(:request, title: 'I do too!', organization: organization, broadcasted_at: 1.day.ago)
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

  describe 'GET /:organization_id/request/:id' do
    subject { -> { get organization_request_path(organization, request, as: user) } }

    let(:request) { create(:request, organization: organization) }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'redirects to the sign in path' do
        subject.call
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, organizations: [create(:organization)]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, organizations: [organization]) }

      context 'request not part of organization' do
        let(:request) { create(:request, organization: create(:organization)) }

        it 'renders not found ' do
          subject.call
          expect(response).to be_not_found
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

  describe 'POST /:organization_id/requests' do
    subject { -> { post organization_requests_path(organization, as: user), params: params } }

    let(:params) { { request: { title: 'Example Question', text: 'How do you do?', hints: ['confidential'] } } }
    let(:user) { create(:user, organizations: [organization]) }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'redirects to the sign in path' do
        subject.call
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, organizations: [create(:organization)]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
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
            { request: { title: 'Message with files', text: 'Did you get this image?',
                         files: [fixture_file_upload('profile_picture.jpg')] } }
          end

          it 'redirects to requests#show' do
            request = organization.requests.first

            expect(response).to redirect_to organization_request_path(organization, request)
          end

          it 'shows success notification' do
            expect(flash[:success]).to eq('Deine Frage wurde erfolgreich an 2 Mitglieder in der Community gesendet')
          end

          it 'schedules a job to broadcast the request' do
            expect(BroadcastRequestJob).to have_been_enqueued.with(organization.requests.first.id)
          end

          describe 'with no text' do
            before { params[:request][:text] = '' }

            it 'redirects to requests#show' do
              request = organization.requests.first
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

        it 'delays the job for the future' do
          expect { subject.call }.to change(DelayedJob, :count).from(0).to(1)
          expect(Delayed::Job.last.run_at).to be_within(1.second).of(organization.requests.first.schedule_send_for)
        end
      end
    end
  end

  describe 'PATCH /:organization_id/requests/:id' do
    subject { -> { patch organization_request_path(organization, request, as: user), params: params } }

    let(:request) { create(:request, title: 'Temp title', organization: organization) }
    let(:params) { { request: { title: 'Changed me' } } }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'redirects to the sign in path' do
        subject.call
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, organizations: [create(:organization)]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, organizations: [organization]) }

      context 'request not part of organization' do
        let(:request) { create(:request, organization: create(:organization)) }

        it 'renders not found ' do
          subject.call
          expect(response).to be_not_found
        end
      end

      context 'request part of organization' do
        context 'request is not planned' do
          it 'does not update the request' do
            expect { subject.call }.not_to(change { request.reload })
          end

          it 'redirects to requests index page with error message' do
            subject.call
            expect(response).to redirect_to(organization_requests_path(request.organization))
            expect(flash[:error]).to eq('Sie können eine bereits verschickte Frage nicht mehr bearbeiten.')
          end
        end

        context 'request is planned' do
          before do
            request.update!(schedule_send_for: 1.day.from_now)
            create_list(:contributor, 2, organization: organization)
            create(:contributor, deactivated_at: 1.day.ago, organization: organization)
            create(:contributor, organization: create(:organization))
          end

          it 'updates the request' do
            expect { subject.call }.to (change { request.reload.title }).from('Temp title').to('Changed me')
          end

          it 'redirects to requests index page with planned filter and success message' do
            subject.call
            expect(response).to redirect_to(organization_requests_path(request.organization_id, filter: :planned))
            expect(flash[:success]).to eq(
              "Ihre Frage wurde erfolgreich geplant, um am #{I18n.l(request.schedule_send_for,
                                                                    format: :long)} an 2 Community-Mitglieder gesendet zu werden."
            )
          end

          it 'delays the job for the future' do
            expect { subject.call }.to change(DelayedJob, :count).from(0).to(1)
            expect(Delayed::Job.last.run_at).to be_within(1.second).of(request.schedule_send_for)
          end

          context 're-scheduled to be sent now' do
            let(:params) { { request: { schedule_send_for: Time.current } } }

            it 'updates the request' do
              expect { subject.call }.to(change { request.reload.schedule_send_for })
            end

            it 'schedules a job to broadcast the request' do
              subject.call

              expect(BroadcastRequestJob).to have_been_enqueued.with(request.id)
            end

            it "redirects to request's show page with success message" do
              subject.call
              expect(response).to redirect_to(organization_request_path(request.organization_id, request))
              expect(flash[:success]).to eq('Deine Frage wurde erfolgreich an 2 Mitglieder in der Community gesendet')
            end
          end
        end
      end
    end
  end

  describe 'DELETE /:organization_id/requests/:id' do
    subject { -> { delete organization_request_path(organization, request, as: user) } }

    let(:request) { create(:request, organization: organization) }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'redirects to the sign in path' do
        subject.call
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, organizations: [create(:organization)]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, organizations: [organization]) }

      context 'request not part of organization' do
        let(:request) { create(:request, organization: create(:organization)) }

        it 'renders not found ' do
          subject.call
          expect(response).to be_not_found
        end
      end

      context 'request part of organization' do
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
    end
  end

  describe 'GET /:organization_id/notifications' do
    let(:request) { create(:request, organization: organization) }
    let!(:older_message) { create(:message, request_id: request.id, created_at: 2.minutes.ago) }
    let(:params) { { last_updated_at: 1.minute.ago } }

    subject { -> { get notifications_organization_request_path(request.organization, request, as: user), params: params } }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'redirects to the sign in path' do
        subject.call
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, organizations: [create(:organization)]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, organizations: [organization]) }

      context 'request not part of organization' do
        let(:request) { create(:request, organization: create(:organization)) }

        it 'renders not found ' do
          subject.call
          expect(response).to be_not_found
        end
      end

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

  describe 'GET /:organization_id/requests/:id/messages-by-contributor' do
    subject { -> { get messages_by_contributor_organization_request_path(organization, request, as: user) } }

    let(:request) { create(:request, organization: organization) }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'redirects to the sign in path' do
        subject.call
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, organizations: [create(:organization)]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, organizations: [organization]) }

      context 'request not part of organization' do
        let(:request) { create(:request, organization: create(:organization)) }

        it 'renders not found ' do
          subject.call
          expect(response).to be_not_found
        end
      end

      context 'request part of organization' do
        let(:message_from_other_request) do
          create(:message, text: 'Not part of request', request: create(:request, organization: organization))
        end
        let(:message_from_other_organization) { create(:message, text: 'Not part of organization', organization: create(:organization)) }
        let(:first_message) do
          create(:message, text: 'First message', sender: create(:contributor, first_name: 'Super', last_name: 'FastReplier'))
        end
        let(:second_message) do
          create(:message, text: 'Second message', sender: create(:contributor, first_name: 'Second', last_name: 'AintBad'))
        end

        before do
          request.update!(messages: [first_message, second_message])
          message_from_other_request
          message_from_other_organization
        end

        it 'renders MessageGroups::MessageGroups component' do
          subject.call
          expect(page).to have_content('Super FastReplier')
          expect(page).to have_content('First message')

          expect(page).to have_content('Second AintBad')
          expect(page).to have_content('Second message')

          expect(page).not_to have_content('Not part of request')
          expect(page).not_to have_content('Not part of organization')
        end
      end
    end
  end

  describe 'GET /:organization_id/requests/:id/stats' do
    subject { -> { get stats_organization_request_path(organization, request, as: user) } }

    let(:request) { create(:request, organization: organization) }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'redirects to the sign in path' do
        subject.call
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, organizations: [create(:organization)]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, organizations: [organization]) }

      context 'request not part of organization' do
        let(:request) { create(:request, organization: create(:organization)) }

        it 'renders not found ' do
          subject.call
          expect(response).to be_not_found
        end
      end

      context 'request part of organization' do
        let(:request) { create(:request, organization: organization) }

        describe 'given a number of requests, replies and photos' do
          before(:each) do
            contributors = create_list(:contributor, 2, organization: organization)
            # not counted since they are from another organization's request
            create_list(:message, 2, request: create(:request, organization: create(:organization)))
            delivered_messages_from_organization = contributors.collect do |contributor|
              [create(:message, :outbound, request: request, recipient: contributor, broadcasted: true),
               create(:message, :with_file, :outbound, request: request, broadcasted: false,
                                                       recipient: contributor,
                                                       attachment: fixture_file_upload('example-image.png'))] # outbound files not counted
            end.flatten
            responsive_recipient = delivered_messages_from_organization.first.recipient
            create_list(:message, 2, request: request, sender: responsive_recipient)
            create(:message, :with_a_photo, sender: responsive_recipient, request: request) # counted
            create(:message, :with_file, sender: responsive_recipient, request: request,
                                         attachment: fixture_file_upload('example-image.png')) # counted
            # Not counted for photos because it's a pdf, counted as a reply because a message record is created
            create(:message, :with_file, sender: responsive_recipient, request: request,
                                         attachment: fixture_file_upload('invalid_profile_picture.pdf'))
          end

          it 'displays the stats' do
            subject.call
            expect(page).to have_css('.InlineMetrics') do |inline_metrics|
              # unique contributors replied / recipients of request
              expect(inline_metrics).to have_css("div[data-testid='unique-contributors-replied-ratio']") do |contributors_replied_ratio|
                expect(contributors_replied_ratio).to have_css("use[href='/icons.svg#icon-single-03-glyph-24']")
                expect(contributors_replied_ratio).to have_css('span[class="Metric-value"]', text: '1/2')
                expect(contributors_replied_ratio).to have_css('span[class="Metric-label"]', text: 'hat geantwortet')
              end

              # total number of replied messages
              expect(inline_metrics).to have_css("div[data-testid='total-replies-count']") do |total_replies|
                expect(total_replies).to have_css("use[href='/icons.svg#icon-a-chat-glyph-24']")
                expect(total_replies).to have_css('span[class="Metric-value"]', text: '5')
                expect(total_replies).to have_css('span[class="Metric-label"]', text: 'empfangene Nachricht')
              end

              # total number of photos
              expect(inline_metrics).to have_css("div[data-testid='photos-count']") do |photos|
                expect(photos).to have_css("use[href='/icons.svg#icon-camera-glyph-24']")
                expect(photos).to have_css('span[class="Metric-value"]', text: '2')
                expect(photos).to have_css('span[class="Metric-label"]', text: 'empfangene Bilder')
              end
            end
          end
        end
      end
    end
  end
end
