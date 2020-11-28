# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages', type: :request do
  describe 'POST /messages/:id/highlight' do
    let(:params) { {} }

    subject do
      lambda do
        post(highlight_message_url(message, format: :json), params: params)
      end
    end

    describe 'given an non-highlighted message' do
      let(:message) { create(:message, highlighted: false) }

      describe 'given highlighted=true' do
        let(:params) { { highlighted: true } }
        it do
          should change { message.reload.highlighted? }.from(false).to(true)
        end
      end

      describe 'given highlighted=false' do
        let(:params) { { highlighted: false } }
        it { should_not(change { message.reload.highlighted? }) }
      end
    end

    describe 'given a highlighted message' do
      let(:message) { create(:message, highlighted: true) }

      describe 'given highlighted=true' do
        let(:params) { { highlighted: true } }
        it { should_not(change { message.reload.highlighted? }) }
      end

      describe 'given highlighted=false' do
        let(:params) { { highlighted: false } }
        it { should change { message.reload.highlighted? }.from(true).to(false) }
      end
    end
  end
end
