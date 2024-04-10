# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessage::ChatMessage, type: :component do
  subject(:component) { render_inline(described_class.new(**params)) }

  let(:params) { { message: message } }

  describe '[class]' do
    subject { component.css('.ChatMessage')[0][:class] }

    describe 'given a non-highlighted message' do
      let(:message) { create(:message, highlighted: false) }

      it { is_expected.not_to include('ChatMessage--highlighted') }
    end

    describe 'given a highlighted message' do
      let(:message) { create(:message, highlighted: true) }

      it { is_expected.to include('ChatMessage--highlighted') }
    end
  end

  describe '.text' do
    subject { component.css('.ChatMessage-text') }

    describe 'given HTML text' do
      let(:message) { create(:message, text: '<h1>Hello!</h1>') }

      it { is_expected.to have_text('<h1>Hello!</h1>') }
    end
  end

  describe 'move action' do
    context 'given an inbound message' do
      let(:message) { create(:message, :inbound) }

      it 'is present' do
        expect(subject).to have_css('a', text: I18n.t('components.chat_message.move'))
      end
    end

    context 'given an outbound message' do
      context 'with a direct enquiry to a contributor from a user' do
        let(:message) { create(:message, :outbound) }

        it 'is present' do
          expect(subject).to have_css('a', text: I18n.t('components.chat_message.move'))
        end
      end

      context 'with a broadcasted message' do
        let(:message) { create(:message, :outbound, broadcasted: true) }

        it 'is hidden' do
          expect(subject).not_to have_css('a', text: I18n.t('components.chat_message.move'))
        end
      end
    end
  end

  describe '.creator_name' do
    subject { component.css('.ChatMessage-footer') }

    context 'given a manually created message' do
      let(:message) { create(:message, creator: create(:user, first_name: 'Princess', last_name: 'Mononoke')) }

      it { is_expected.to have_text(I18n.t('components.chat_message.created_by', name: 'Princess Mononoke')) }

      context 'with a creator with no name' do
        let(:message) { create(:message, creator: create(:user, first_name: '', last_name: '')) }

        it {
          expect(subject).to have_text(I18n.t('components.chat_message.created_by',
                                              name: I18n.t('components.chat_message.anonymous_creator')))
        }
      end
    end

    context 'given a non-manually created message' do
      let(:message) { create(:message) }

      it { is_expected.to have_text(I18n.t('components.chat_message.copy')) }
      it { is_expected.not_to have_text(I18n.t('components.chat_message.created_by', name: '')) }
    end
  end
end
