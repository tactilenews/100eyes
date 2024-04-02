# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Threema', type: :request do
  let(:data_processing_consent) { true }
  let(:contributor) { create(:contributor) }
  let(:additional_consent) { true }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding', organization_id: create(:organization).id }) }
  let(:params) { { jwt: jwt } }
  let(:threema) { instance_double(Threema) }
  let(:threema_lookup_double) { instance_double(Threema::Lookup) }
  before do
    allow(Threema).to receive(:new).and_return(threema)
    allow(Threema::Lookup).to receive(:new).with({ threema: threema }).and_return(threema_lookup_double)
    allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
    allow(Setting).to receive(:threema_configured?).and_return(true)
  end

  describe 'POST /onboarding/threema' do
    let(:attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        threema_id: 'ABCD1234',
        data_processing_consent: data_processing_consent,
        additional_consent: additional_consent
      }
    end

    let(:params) { { jwt: jwt, contributor: attrs, context: :contributor_signup } }

    subject { -> { post onboarding_threema_path, params: params } }

    it 'creates contributor' do
      expect { subject.call }.to change(Contributor, :count).by(1)

      contributor = Contributor.first
      expect(contributor).to have_attributes(
        first_name: 'Zora',
        last_name: 'Zimmermann',
        threema_id: 'ABCD1234',
        data_processing_consent: data_processing_consent,
        additional_consent: additional_consent
      )
      expect(contributor.json_web_token).to have_attributes(
        invalidated_jwt: jwt
      )
    end

    it { should enqueue_job(ThreemaAdapter::Outbound::Text) }

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
      it_behaves_like 'an ActivityNotification', 'OnboardingCompleted'
    end

    context 'given an invalid Threema ID' do
      before do
        allow(threema_lookup_double).to receive(:key).and_return(nil)
      end

      it 'displays validation errors' do
        subject.call
        parsed = Capybara::Node::Simple.new(response.body)
        fields = parsed.all('.Field')
        threema_id_field = fields.find { |f| f.has_text? 'Threema ID' }
        expect(threema_id_field).to have_text('Threema ID ist ungültig, bitte überprüfen.')
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end

      it 'has 422 status code' do
        subject.call
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'given an existing threema ID' do
      let!(:contributor) { create(:contributor, **attrs) }

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
          threema_id: 'ABCD1234',
          data_processing_consent: data_processing_consent,
          additional_consent: additional_consent
        )
      end
    end

    describe 'with unsigned jwt' do
      let(:jwt) { 'INCORRECT_TOKEN' }

      it 'renders unauthorized page' do
        subject.call

        expect(response).not_to be_successful
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

        expect(response).not_to be_successful
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end
    end
  end
end
