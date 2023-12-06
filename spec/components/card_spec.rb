# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Card::Card, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  it { is_expected.to have_css('.Card') }
end
