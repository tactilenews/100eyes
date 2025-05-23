# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Whatsapp' do
  let!(:organization) do
    create(:organization,
           whats_app_server_phone_number: whats_app_server_phone_number,
           three_sixty_dialog_client_api_key: three_sixty_dialog_client_api_key,
           onboarding_allowed: onboarding_allowed,
           users_count: 1)
  end
  let!(:admin) { create_list(:user, 2, admin: true) }
  let(:whats_app_server_phone_number) { nil }
  let(:three_sixty_dialog_client_api_key) { nil }
  let(:onboarding_allowed) { { whats_app: true } }
  let(:params) { { jwt: jwt } }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
  # onboarding should work also when a contributor in another organization has the same number
  let!(:existing_contributor) { create(:contributor, whats_app_phone_number: '+491512454567') }

  describe 'GET /{organization_id}/onboarding/whatsapp' do
    subject { -> { get organization_onboarding_whats_app_path(organization), params: params } }

    describe 'when WhatsApp was not configured' do
      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'when 360dialog is configured' do
      let(:three_sixty_dialog_client_api_key) { 'valid_api_key' }

      context 'but onboarding has been disallowed by an admin' do
        let(:onboarding_allowed) { { whats_app: false } }

        it 'returns a 404 not found' do
          subject.call

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'and onboarding has not been disallowed' do
        it 'returns a 200 ok' do
          subject.call

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe 'POST /{organization_id}/onboarding/whatsapp' do
    subject { -> { post organization_onboarding_whats_app_path(organization), params: params } }

    let(:params) { { jwt: jwt, contributor: attrs, context: :contributor_signup } }
    let(:attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        whats_app_phone_number: '+491512454567',
        data_processing_consent: true
      }
    end

    describe 'when WhatsApp was not configured' do
      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'when 360dialog is configured' do
      let(:three_sixty_dialog_client_api_key) { 'valid_api_key' }

      context 'but onboarding has been disallowed by an admin' do
        let(:onboarding_allowed) { { whats_app: false } }

        it 'returns a 404 not found' do
          subject.call

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'and onboarding has not been disallowed' do
        let(:welcome_message_payload) do
          {
            messaging_product: 'whatsapp',
            recipient_type: 'individual',
            to: Contributor.unscoped.last.whats_app_phone_number.split('+').last,
            type: 'template',
            template: {
              language: {
                policy: 'deterministic',
                code: 'de'
              },
              name: "welcome_message_#{organization.project_name.parameterize.underscore}"
            }
          }
        end

        it 'creates the contributor' do
          expect { subject.call }.to change(Contributor, :count).by(1)

          contributor = Contributor.unscoped.last
          expect(contributor).to have_attributes(
            first_name: 'Zora',
            last_name: 'Zimmermann',
            whats_app_phone_number: '+491512454567',
            data_processing_consent: true,
            organization: organization
          )
          expect(contributor.json_web_token).to have_attributes(
            invalidated_jwt: jwt
          )
        end

        it 'enqueues a job with welcome message' do
          subject.call

          contributor = Contributor.unscoped.last
          expect(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).to have_been_enqueued.with(
            contributor_id: contributor.id,
            type: :welcome_message_template
          )
        end

        it 'redirects to success page' do
          subject.call
          expect(response).to redirect_to organization_onboarding_success_path(organization, jwt: nil)
        end

        it 'invalidates the jwt' do
          expect { subject.call }.to change(JsonWebToken, :count).by(1)

          json_web_token = JsonWebToken.where(invalidated_jwt: jwt)
          expect(json_web_token).to exist
        end

        context 'creates an ActivityNotification' do
          it_behaves_like 'an ActivityNotification', 'OnboardingCompleted', 3
        end
      end
    end
  end
end
