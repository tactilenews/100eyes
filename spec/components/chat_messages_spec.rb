# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessages::ChatMessages, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { messages: [] } }
  it { should have_css('.ChatMessages') }
end
