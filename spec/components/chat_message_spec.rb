# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessage::ChatMessage, type: :component do
  subject(:component) { render_inline(described_class.new(**params)) }
  describe '.text' do
    subject { component.css('.ChatMessage-text') }
    describe 'is sanitized' do
      let(:message) { build(:message, text: '<h1>Hello!</h1>', created_at: Time.zone.now) }
      let(:params) { { message: message } }
      it { should have_text('<h1>Hello!</h1>') }
    end
  end
end
