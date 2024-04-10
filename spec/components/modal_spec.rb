# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Modal::Modal, type: :component do
  subject { render_inline(described_class.new(**params)) { 'Hello World!' } }

  let(:params) { {} }

  it { is_expected.to have_css('.Modal') }
  it { is_expected.to have_text('Hello World') }
end
