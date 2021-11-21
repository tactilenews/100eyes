# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorSignalSettings::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { contributor: contributor } }

  let(:contributor) do
    create(:contributor,
           first_name: 'Max',
           last_name: 'Mustermann',
           signal_phone_number: '+4915112345678',
           signal_onboarding_completed_at: onboarding_completed_at,
           created_at: '2021-01-01')
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
    it { should have_css('button[data-copy-button-copy-value$="http://test.host/onboarding/signal/link"]') }
  end
end
