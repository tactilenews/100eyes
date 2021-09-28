# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorCoreDataForm::ContributorCoreDataForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { create(:contributor) }
  let(:params) { { contributor: contributor } }

  it { should have_css('form') }
end
