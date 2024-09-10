# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'Signal' do
  let(:organization) { create(:organization, signal_server_phone_number: nil) }

  describe 'GET /:organization_id/add-signal' do
    subject { -> { get organization_signal_add_path(organization, as: user) } }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, admin: false, organizations: [organization]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, admin: true) }

      it 'should be successful' do
        subject.call
        expect(response).to be_successful
      end

      it 'renders a form to add signal_server_phone_number' do
        subject.call
        expect(page).to have_css("form[action='/#{organization.id}/signal/add']") do |form|
          expect(form).to have_css('input[id="organization[signal_server_phone_number]"]')
        end
      end
    end
  end

  describe 'PATCH /:organization_id/add-signal' do
    subject { -> { patch organization_signal_add_path(organization, as: user), params: params } }

    let(:params) { { organization: { signal_server_phone_number: '+4912345678' } } }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, admin: false, organizations: [organization]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, admin: true) }

      it "updates the organization's signal_server_phone_number" do
        expect { subject.call }.to (change { organization.reload.signal_server_phone_number }).from(nil).to('+4912345678')
      end

      it 'redirects to /signal/register' do
        subject.call
        expect(response).to redirect_to(organization_signal_register_path(organization))
      end

      it 'renders a form to register' do
        subject.call
        follow_redirect!
        expect(page).to have_css("form[action='/#{organization.id}/signal/register']") do |form|
          expect(form).to have_css('input[id="organization[signal][captcha]"]')
        end
      end
    end
  end

  describe 'POST /:organization_id/signal/register' do
    subject { -> { post organization_signal_register_path(organization, as: user), params: params } }

    let(:params) { { organization: { signal: { captcha: 'signalcaptcha://signal-hcaptcha.valid-captcha' } } } }
    let(:uri) { URI.parse('http://signal:8080/v1/register/+4912345678') }

    before do
      organization.update!(signal_server_phone_number: '+4912345678')
      stub_request(:post, uri).to_return(status: 201)
    end

    context 'unauthenticated' do
      let(:user) { nil }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, admin: false, organizations: [organization]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, admin: true) }

      it 'redirects to /signal/verify' do
        subject.call
        expect(response).to redirect_to(organization_signal_verify_path(organization))
      end

      it 'renders a form to verify' do
        subject.call
        follow_redirect!
        expect(page).to have_css("form[action='/#{organization.id}/signal/verify']") do |form|
          expect(form).to have_css('input[id="organization[signal][token]"]')
        end
      end

      context 'given the register is unsucessful' do
        let(:error_message) { 'Invalid captcha' }

        before do
          allow(Sentry).to receive(:capture_exception)
          stub_request(:post, uri).to_return(status: 400, body: { error: error_message }.to_json)
        end

        it 'reports the error' do
          expect(Sentry).to receive(:capture_exception).with(SignalAdapter::BadRequestError.new(error_code: 400, message: error_message))

          subject.call
        end
      end
    end
  end

  describe 'POST /:organization_id/signal/verify' do
    subject { -> { post organization_signal_verify_path(organization, as: user), params: params } }

    let(:params) { { organization: { signal: { token: '123456' } } } }
    let(:uri) { URI.parse('http://signal:8080/v1/register/+4912345678/verify/123456') }

    before do
      organization.update!(signal_server_phone_number: '+4912345678')
      stub_request(:post, uri).to_return(status: 201)
    end

    context 'unauthenticated' do
      let(:user) { nil }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, admin: false, organizations: [organization]) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, admin: true) }

      it 'schedules a job to set trust mode to always' do
        expect { subject.call }.to have_enqueued_job(SignalAdapter::SetTrustModeJob).with(signal_server_phone_number: '+4912345678')
      end

      context 'given the verify is unsucessful' do
        let(:error_message) { 'Verify error: StatusCode: 400' }

        before do
          allow(Sentry).to receive(:capture_exception)
          stub_request(:post, uri).to_return(status: 400, body: { error: error_message }.to_json)
        end

        it 'reports the error' do
          expect(Sentry).to receive(:capture_exception).with(SignalAdapter::BadRequestError.new(error_code: 400, message: error_message))

          subject.call
        end
      end
    end
  end
end
