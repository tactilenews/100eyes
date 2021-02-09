# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Threema::WebhookController do
  let(:params) do
    {
      'from' => 'V5EA564T',
      'to' => '*100EYES',
      'messageId' => 'dfbe859c44f15125',
      'date' => '1612808574',
      'nonce' => 'b1c80cf818e289e6b1966b9bcab6fb9fb5e31862b46d8f98',
      'box' => 'ENCRYPTED FILE',
      'mac' => '8c58e9d4d9ad1aa960a58a1f11bcf712e9fcd50319778762824d8259dcbdc639',
      'nickname' => 'matt.rider'
    }
  end
  let(:message) { build(:message) }
  let(:threema_mock) { double('Threema', content: 'Hello World!') }
  let(:threema) { instance_double(Threema) }

  before do
    allow(Threema).to receive(:new).and_return(threema)
    allow(threema).to receive(:receive).and_return(threema_mock)
  end

  describe '#message' do
    subject { post '/threema/webhook', params: params }

    context 'No contributor' do
      it 'does not create a message' do
        expect { subject }.not_to change(Message, :count)
      end
    end

    context 'With known contributor' do
      let!(:contributor) { create(:contributor, threema_id: 'V5EA564T') }
      let!(:request) { create(:request) }

      it 'creates a message' do
        expect { subject }.to change(Message, :count).from(0).to(1)
      end
    end
  end
end
