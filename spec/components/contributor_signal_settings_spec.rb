# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorSignalSettings::ContributorSignalSettings, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { contributor: contributor, organization: organization } }
  let(:complete_onboarding_link) do
    organization_onboarding_signal_link_path(organization, signal_onboarding_token: contributor.signal_onboarding_token)
  end
  let(:organization) { create(:organization) }

  let(:contributor) do
    create(:contributor,
           first_name: 'Max',
           last_name: 'Mustermann',
           signal_phone_number: '+4915112345678',
           signal_onboarding_completed_at: onboarding_completed_at,
           created_at: '2021-01-01',
           organization: organization)
  end

  let(:onboarding_completed_at) { Time.zone.now }

  it { should have_css('h2', text: 'Signal') }
  it { should have_css('p', text: 'Max Mustermann hat sich mit der Handynummer 0151 1234 5678 angemeldet.') }

  context 'given a contributor with incomplete onboarding' do
    let(:onboarding_completed_at) { nil }

    it {
      should have_css('p',
                      text: 'Max Mustermann hat sich am 01.01.2021 via Signal angemeldet, die Anmeldung aber noch nicht abgeschlossen.')
    }
    it { should have_css('p', text: 'Sende Max einen Link mit Hinweisen zum Abschließen der Anmeldung.') }
    it { should have_css("button[data-copy-button-copy-value$='#{complete_onboarding_link}']") }
  end

  describe 'given a contributor with signal_uuid' do
    let(:contributor) do
      create(:contributor,
             first_name: 'Max',
             last_name: 'Mustermann',
             signal_phone_number: nil,
             signal_uuid: signal_uuid,
             signal_onboarding_completed_at: onboarding_completed_at,
             created_at: '2021-01-01')
    end

    let(:onboarding_completed_at) { Time.current }
    let(:signal_uuid) { 'valid_uuid' }

    it { should have_css('h2', text: 'Signal') }
    it { should have_css('p', text: 'Max Mustermann hat sich mit der UUID valid_uuid angemeldet.') }

    context 'given a contributor with incomplete onboarding' do
      let(:onboarding_completed_at) { nil }
      let(:signal_uuid) { nil }

      it {
        should have_css('p',
                        text: 'Max Mustermann hat sich am 01.01.2021 via Signal angemeldet, die Anmeldung aber noch nicht abgeschlossen.')
      }
      it { should have_css('p', text: 'Sende Max einen Link mit Hinweisen zum Abschließen der Anmeldung.') }
      it { should have_css("button[data-copy-button-copy-value$='#{complete_onboarding_link}']") }
    end
  end
end
