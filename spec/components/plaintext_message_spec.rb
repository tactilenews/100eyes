# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlaintextMessage::PlaintextMessage, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { message: 'Hello World!' } }
  it { should have_css('.PlaintextMessage') }
end
