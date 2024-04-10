# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GdprModal::GdprModal, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  before { allow(Setting).to receive(:onboarding_data_protection_link).and_return('https://example.org/privacy') }

  it { is_expected.to have_css('.GdprModal') }
  it { is_expected.to have_css('h2', text: 'Datenschutz') }
  it { is_expected.to have_link('Datenschutzerklärung', href: 'https://example.org/privacy') }
end
