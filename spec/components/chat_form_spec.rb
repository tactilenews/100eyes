# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatForm::ChatForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { contributor: build(:contributor, id: 42) } }

  it { is_expected.to have_css('.ChatForm') }
end
