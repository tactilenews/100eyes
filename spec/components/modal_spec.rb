# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Modal::Modal, type: :component do
  subject { render_inline(described_class.new(**params)) { 'Hello World!' } }
  let(:params) { {} }

  it { should have_css('.Modal') }
  it { should have_text('Hello World') }
end
