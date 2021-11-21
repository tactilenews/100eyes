# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorEmailSettings::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) do
    create(:contributor,
           email: 'muster@example.org',
           first_name: 'Max',
           last_name: 'Mustermann',
           created_at: '2021-01-01')
  end

  let(:params) { { contributor: contributor } }

  it { should have_css('h2', text: 'E-Mail') }
  it { should have_css('p', text: 'Max Mustermann hat sich via E-Mail angemeldet.') }

  it { should have_css("form[action='/contributors/#{contributor.id}']") }
  it { should have_css('input[type="email"][value="muster@example.org"]') }
  it { should have_css('button', text: 'Speichern') }
end
