# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SidebarItem::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }
  it { should have_css('article.SidebarItem') }

  context 'if active' do
    let(:params) { { active: true } }
    it { should have_css('article.SidebarItem--active') }
  end
end
