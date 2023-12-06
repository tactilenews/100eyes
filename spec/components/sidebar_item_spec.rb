# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SidebarItem::SidebarItem, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  it { is_expected.to have_css('article.SidebarItem') }

  context 'if active' do
    let(:params) { { active: true } }

    it { is_expected.to have_css('article.SidebarItem--active') }
  end
end
