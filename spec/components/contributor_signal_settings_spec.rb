# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorSignalSettings::ContributorSignalSettings, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { contributor: contributor } }

  let(:contributor) do
    create(:contributor,
           first_name: 'Max',
           last_name: 'Mustermann',
           signal_phone_number: '+4915112345678',
           created_at: '2021-01-01')
  end

  it { should have_css('h2', text: 'Signal') }
  it { should have_css('p', text: 'Max Mustermann hat sich mit der Handynummer 0151 1234 5678 angemeldet.') }
end
