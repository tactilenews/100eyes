# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GdprModal::GdprModal, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization, onboarding_data_protection_link: 'https://example.org/privacy') }
  let(:params) { { organization: organization } }

  it { should have_css('.GdprModal') }
  it { should have_css('h2', text: 'Datenschutz') }
  it { should have_link('Datenschutzerklärung', href: 'https://example.org/privacy') }
end
