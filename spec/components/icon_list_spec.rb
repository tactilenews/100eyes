# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IconList::IconList, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { elements: elements } }
  let(:elements) do
    [
      { icon: 'my-icon', title: 'My Title', text: 'Lorem Ipsum' }
    ]
  end

  it { is_expected.to have_css('.IconList') }
  it { is_expected.to have_css('.IconList-title', text: 'My Title') }
  it { is_expected.to have_text('Lorem Ipsum') }
end
