# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MoveMessageForm::MoveMessageForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:message) { create(:message) }
  let(:params) { { message: message } }

  it { should have_css('form') }
end
