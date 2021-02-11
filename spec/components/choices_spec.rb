# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Choices::Choices, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { id: 'my-id' } }
  it { should have_css('.Choices') }
end
