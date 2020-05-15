# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message::Message, type: :component do
  subject(:component) { render_inline(described_class.new(**params)) }
  describe '.text' do
    subject { component.css('.Message-text') }
    describe 'is sanitized' do
      let(:reply) { build(:reply, text: '<h1>Hello!</h1>', created_at: Time.zone.now) }
      let(:params) { { message: reply } }
      it { should have_text('<h1>Hello!</h1>') }
    end
  end
end
