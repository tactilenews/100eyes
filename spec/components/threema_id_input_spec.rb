# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaIdInput::ThreemaIdInput, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { id: :threema_id } }
  it { should have_css('input[pattern="[A-Za-z0-9]{8}"][name="threema_id"]') }
end
