# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Checkbox::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  it { should have_css('input[type="checkbox"]') }
end
