# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hero::Hero, type: :component do
  subject { render_inline(described_class.new(organization_id: organization, **params)) }

  let(:organization) { create(:organization) }
  let(:params) { {} }
  it { should have_css('.Hero') }
end
