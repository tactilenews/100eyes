# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TabBar::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:params) { { items: items } }

  let(:items) do
    {
      '/a': { label: 'Link A', active: true },
      '/b': { label: 'Link B' }
    }
  end

  it { should have_css('.TabBar') }

  it 'renders list of items' do
    expect(subject).to have_css('.TabBar-item--active', text: 'Link A')
    expect(subject).to have_css('a[href="/a"]', text: 'Link A')

    expect(subject).not_to have_css('.TabBar-item--active', text: 'Link B')
    expect(subject).to have_css('a[href="/b"]', text: 'Link B')
  end

  context 'with counts' do
    let(:items) { { '/a': { label: 'Link A', count: 3 } } }

    it { should have_css('.TabBar-item .TabBar-count', text: 3) }
  end
end
