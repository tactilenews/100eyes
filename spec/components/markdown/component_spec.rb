# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Markdown::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { raw: '' } }
  it { should have_css('.Markdown') }
end
