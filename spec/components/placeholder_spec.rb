# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Placeholder::Placeholder, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  it { is_expected.to have_css('.Placeholder') }
end
