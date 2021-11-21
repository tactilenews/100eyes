# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Excerpt::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { title: 'Lorem Ipsum', text: 'dolor sit amet', date: 2.days.ago, link: '#' } }
  it { should have_css('.Excerpt') }
end
