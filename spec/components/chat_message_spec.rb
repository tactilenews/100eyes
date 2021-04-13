# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessage::ChatMessage, type: :component do
  subject(:component) { render_inline(described_class.new(**params)) }
  let(:params) { { message: message } }

  describe '[class]' do
    subject { component.css('.ChatMessage')[0][:class] }

    describe 'given a non-highlighted message' do
      let(:message) { create(:message, highlighted: false) }
      it { should_not include('ChatMessage--highlighted') }
    end

    describe 'given a highlighted message' do
      let(:message) { create(:message, highlighted: true) }
      it { should include('ChatMessage--highlighted') }
    end
  end

  describe '.text' do
    subject { component.css('.ChatMessage-text') }

    describe 'given HTML text' do
      let(:message) { create(:message, text: '<h1>Hello!</h1>') }
      it { should have_text('<h1>Hello!</h1>') }
    end
  end

  describe 'move action' do
    context 'given an inbound message' do
      let(:message) { create(:message) }

      it 'is present' do
        expect(subject).to have_css('a', text: I18n.t('components.chat_message.move'))
      end
    end

    context 'given an outbound message' do
      let(:message) { create(:message, sender: nil) }

      it 'is hidden' do
        expect(subject).to_not have_css('a', text: I18n.t('components.chat_message.move'))
      end
    end
  end
end
