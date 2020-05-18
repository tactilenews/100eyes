# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Page::Page, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }
  it { should have_css('.Page') }
end
