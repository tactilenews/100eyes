# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Email', type: :request do
  let(:email) { 'zora@example.org' }
  let(:data_processing_consent) { true }
  let(:additional_consent) { true }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
  let(:params) { { jwt: jwt } }

  describe 'POST /onboarding/email' do
    let(:attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        email: email,
        data_processing_consent: data_processing_consent,
        additional_consent: additional_consent
      }
    end

    let(:params) { { jwt: jwt, contributor: attrs, context: :contributor_signup } }

    subject { -> { post onboarding_email_path, params: params } }

    it 'creates contributor' do
      expect { subject.call }.to change(Contributor, :count).by(1)

      contributor = Contributor.first
      expect(contributor).to have_attributes(
        first_name: 'Zora',
        last_name: 'Zimmermann',
        email: email,
        data_processing_consent: data_processing_consent,
        additional_consent: additional_consent
      )
      expect(contributor.json_web_token).to have_attributes(
        invalidated_jwt: jwt
      )
    end

    it {
      should enqueue_job(ActionMailer::MailDeliveryJob).with(
        'PostmarkAdapter::Outbound',
        'welcome_email',
        'deliver_now',
        {
          params: anything,
          args: []
        }
      )
    }

    it 'redirects to success page' do
      subject.call
      expect(response).to redirect_to onboarding_success_path
    end

    it 'invalidates the jwt' do
      expect { subject.call }.to change(JsonWebToken, :count).by(1)

      json_web_token = JsonWebToken.where(invalidated_jwt: jwt)
      expect(json_web_token).to exist
    end

    context 'creates an ActivityNotification' do
      it_behaves_like 'activity_notifications', 'OnboardingCompleted'
    end

    context 'given invalid email address' do
      let(:email) { 'invalid-email' }

      it 'displays validation errors' do
        subject.call
        parsed = Capybara::Node::Simple.new(response.body)
        fields = parsed.all('.Field')
        email_field = fields.find { |f| f.has_text? 'E-Mail' }
        expect(email_field).to have_text('ist nicht gültig')
      end

      it 'has 422 status code' do
        subject.call
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without data processing consent' do
      let(:data_processing_consent) { false }

      it 'displays validation errors' do
        subject.call
        parsed = Capybara::Node::Simple.new(response.body)
        fields = parsed.all('.Field')
        data_processing_consent_field = fields.find { |f| f.has_text? 'Datenschutzerklärung' }
        expect(data_processing_consent_field).to have_text('muss akzeptiert werden')
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end

      it 'has 422 status code' do
        subject.call
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without additional consent' do
      let(:additional_consent) { false }

      it 'creates contributor without additional consent' do
        expect { subject.call }.to change(Contributor, :count).by(1)

        contributor = Contributor.first
        expect(contributor).to have_attributes(
          first_name: 'Zora',
          last_name: 'Zimmermann',
          email: email,
          data_processing_consent: data_processing_consent,
          additional_consent: additional_consent
        )
      end
    end

    describe 'given an existing email address' do
      let!(:contributor) { create(:contributor, **attrs.merge(json_web_token: create(:json_web_token, invalidated_jwt: :jwt))) }

      it 'redirects to success page' do
        subject.call
        expect(response).to redirect_to onboarding_success_path
      end

      it 'invalidates the jwt' do
        expect { subject.call }.to change(JsonWebToken, :count).by(1)

        json_web_token = JsonWebToken.where(invalidated_jwt: jwt)
        expect(json_web_token).to exist
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end
    end

    describe 'with unsigned jwt' do
      let(:jwt) { 'INCORRECT_TOKEN' }

      it 'renders unauthorized page' do
        subject.call

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end
    end

    describe 'with invalidated jwt' do
      let!(:invalidated_jwt) { create(:json_web_token, invalidated_jwt: 'INVALID_JWT') }
      let(:jwt) { 'INVALID_JWT' }

      it 'renders unauthorized page' do
        subject.call

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end
    end
  end
end
