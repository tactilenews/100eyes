# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitButton::SubmitButton, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { style: :secondary } }
  it { should have_css('button[type="submit"].Button.Button--secondary') }
end
