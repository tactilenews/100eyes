# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatForm::ChatForm, type: :component do
  include DateTimeHelper
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { contributor: build(:contributor, id: 42) } }
  it { should have_css('.ChatForm') }

  context 'without reply_to set' do
    it 'should not have a hidden reply_to input field' do
      expect(subject).not_to have_css('input#message_reply_to_id', visible: false)
    end

    it 'should have a textarea with placeholder' do
      expect(subject).to have_field('message[text]', placeholder: I18n.t('components.chat_form.placeholder'))
    end
  end

  context 'with reply_to set' do
    let(:reply_to) { create(:message) }
    before do
      params[:reply_to] = reply_to
    end

    it 'should have a hidden reply_to input field' do
      expect(subject).to have_css('input#message_reply_to_id', visible: false)
    end

    it 'should have the message prefilled' do
      expect(subject).to have_css('textarea', text: I18n.t('components.chat_form.reply_to_reference', date: date_time(reply_to.updated_at)))
    end
  end
end
