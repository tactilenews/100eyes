# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IconList::IconList, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {list: 'how_it_works'} }
  it { should have_css('.IconList') }
end