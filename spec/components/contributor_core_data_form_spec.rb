# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorCoreDataForm::ContributorCoreDataForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { create(:contributor, first_name: 'Zora', last_name: 'Zimmermann') }
  let(:params) { { contributor: contributor } }

  it { is_expected.to have_css('form') }
  it { is_expected.to have_css('h1', text: 'Stammdaten bearbeiten') }
  it { is_expected.to have_css('p', text: 'Zora Zimmermann') }
end
