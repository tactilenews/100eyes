# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatForm::ChatForm, type: :component do
  include DateTimeHelper
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, organization: organization) }
  let(:params) { { contributor: contributor, organization: organization } }
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
    let(:reply_to) { create(:message, :with_request) }
    before do
      params[:reply_to] = reply_to
    end

    it 'should have a hidden reply_to input field' do
      expect(subject).to have_css('input#message_reply_to_id', visible: false)
    end
  end
end
