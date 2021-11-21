# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IconList::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { elements: elements } }
  let(:elements) do
    [
      { icon: 'my-icon', title: 'My Title', text: 'Lorem Ipsum' }
    ]
  end

  it { should have_css('.IconList') }
  it { should have_css('.IconList-title', text: 'My Title') }
  it { should have_text('Lorem Ipsum') }
end
