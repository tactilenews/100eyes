# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatForm::ChatForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { user: build(:user, id: 42) } }
  it { should have_css('.ChatForm') }
end
