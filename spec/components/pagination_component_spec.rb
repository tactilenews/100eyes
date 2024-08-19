# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pagination::Pagination, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:organization) { create(:organization) }
  let(:current_page_instance) { Kaminari::Helpers::Paginator::PageProxy.new({ total_pages: 3 }, current_page, nil) }
  let(:current_page) { 1 }
  let(:pages) { [1, 2, 3] }
  let(:pages_enumerator) do
    pages.map do |page|
      Kaminari::Helpers::Paginator::PageProxy.new(
        { total_pages: pages.size, left: page - 1, right: pages.size - page, window: pages.size,
          current_page: current_page_instance }, page, nil
      )
    end.each
  end
  let(:params) do
    { current_page: current_page_instance, remote: false, pages: pages_enumerator, path: organization_contributors_path(organization) }
  end

  it { is_expected.to have_css('.Pagination') }

  context 'with query param, query param is maintained in pagination list item' do
    before do
      params[:query] = { state: 'inactive' }
    end
    it { is_expected.to have_css("a[href='/#{organization.id}/contributors/page/#{pages.second}?state=inactive']") }
    it { is_expected.to have_css("a[href='/#{organization.id}/contributors/page/#{pages.third}?state=inactive']") }
  end
end
