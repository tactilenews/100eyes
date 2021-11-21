# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Icon::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { icon: :heart } }
  it { should have_css('svg.Icon > use[href="/icons.svg#icon-heart-glyph-24"]') }
  it { should have_css('svg.Icon[aria-hidden="true"]') }

  context 'if label is not empty' do
    let(:params) { { icon: :heart, label: 'Like' } }

    it { should_not have_css('[aria-hidden="true"]') }
    it { should have_css('svg.Icon[aria-label="Like"]') }
  end
end
