# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatForm::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { contributor: build(:contributor, id: 42) } }
  it { should have_css('.ChatForm') }
end
