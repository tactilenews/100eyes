# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorCoreDataForm::ContributorCoreDataForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, first_name: 'Zora', last_name: 'Zimmermann', organization: organization) }
  let(:params) { { contributor: contributor, organization: organization } }

  it { should have_css('form') }
  it { should have_css('h1', text: 'Stammdaten bearbeiten') }
  it { should have_css('p', text: 'Zora Zimmermann') }
end
