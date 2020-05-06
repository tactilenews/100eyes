# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Icon::Icon, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { icon: 'heart' } }
  it { should have_css('svg.Icon > use[xlink:href="/icons.svg#nc-icon-heart-glyph-48"]') }
end
