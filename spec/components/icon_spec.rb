# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Icon::Icon, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { icon: :heart } }

  it { is_expected.to have_css('svg.Icon > use[href="/icons.svg#icon-heart-glyph-24"]') }
  it { is_expected.to have_css('svg.Icon[aria-hidden="true"]') }

  context 'if label is not empty' do
    let(:params) { { icon: :heart, label: 'Like' } }

    it { is_expected.not_to have_css('[aria-hidden="true"]') }
    it { is_expected.to have_css('svg.Icon[aria-label="Like"]') }
  end
end
