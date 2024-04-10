# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TabBar::TabBar, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { items: items } }

  let(:items) do
    [{ url: '/a', label: 'Link A', active: true },
     { url: '/b', label: 'Link B' }]
  end

  it { is_expected.to have_css('.TabBar') }

  it 'renders list of items' do
    expect(subject).to have_css('.TabBar-item--active', text: 'Link A')
    expect(subject).to have_css('a[href="/a"]', text: 'Link A')

    expect(subject).not_to have_css('.TabBar-item--active', text: 'Link B')
    expect(subject).to have_css('a[href="/b"]', text: 'Link B')
  end

  context 'with counts' do
    let(:items) { [{ url: '/a', label: 'Link A', count: 3 }] }

    it { is_expected.to have_css('.TabBar-item .TabBar-count', text: 3) }
  end

  context 'without url' do
    let(:items) { [{ label: 'Button A' }] }

    it { is_expected.to have_css('button.Button') }
  end

  context 'with icon' do
    let(:items) { [{ icon: 'filter-tool' }] }

    it { is_expected.to have_css('.Icon.Icon--inline') }
  end
end
