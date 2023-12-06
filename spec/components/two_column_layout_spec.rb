# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TwoColumnLayout::TwoColumnLayout, type: :component do
  subject do
    render_inline(described_class.new(id: 'layout')) do |component|
      component.sidebar { 'Sidebar' }
      'Content'
    end
  end

  it { is_expected.to have_css('.TwoColumnLayout') }
  it { is_expected.to have_css('.TwoColumnLayout-sidebar', text: 'Sidebar') }
  it { is_expected.to have_text('Content') }
end
