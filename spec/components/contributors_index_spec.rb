# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorsIndex::ContributorsIndex, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:params) do
    {
      organization: organization,
      contributors: Kaminari.paginate_array(create_list(:contributor, 3)).page(1),
      state: :active,
      active_count: 2,
      inactive_count: 1,
      unsubscribed_count: 0,
      filter_count: 0,
      tag_list: []
    }
  end

  it { is_expected.to have_css('.ContributorsIndex') }
end
