# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TwoColumnLayout::Component, type: :component do
  subject do
    render_inline(described_class.new(id: 'layout')) do |component|
      component.sidebar { 'Sidebar' }
      'Content'
    end
  end

  it { should have_css('.TwoColumnLayout') }
  it { should have_css('.TwoColumnLayout-sidebar', text: 'Sidebar') }
  it { should have_css('.TwoColumnLayout-content', text: 'Content') }
end
