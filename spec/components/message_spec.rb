# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message::Message, type: :component do
  subject(:component) { render_inline(described_class.new(**params)) }
  describe '.text' do
    subject { component.css('.Message-text') }
    describe 'is sanitized' do
      let(:params) { { message: '<h1>Hello!</h1>' } }
      it { should have_text('<h1>Hello!</h1>') }
    end
  end
end
