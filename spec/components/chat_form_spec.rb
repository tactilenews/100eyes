# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatForm::ChatForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { contributor: build(:contributor, id: 42) } }
  it { should have_css('.ChatForm') }

  context 'without reply_to set' do
    it 'should not have a hidden reply_to input field' do
      expect(subject).not_to have_css('input#message_reply_to_id', visible: false)
    end
  end

  context 'with reply_to set' do
    before do
      params[:reply_to] = create(:message)
    end

    it 'should have a hidden reply_to input field' do
      expect(subject).to have_css('input#message_reply_to_id', visible: false)
    end
  end
end
