# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestForm::RequestForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { request: build(:request) } }
  it { should have_css('.RequestForm') }
end
