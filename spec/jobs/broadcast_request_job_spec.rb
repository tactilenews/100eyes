# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastRequestJob do
  describe '#perform_later(request_id:)' do
    subject { -> { described_class.new.perform(request_id: request.id) } }

    let(:request) { create(:request) }

    context 'given the request has been deleted' do
      before { request.destroy }

      it 'does not rails an error' do
        expect { subject.call }.not_to raise_error
      end

      it 'does not create a Message instance' do
        expect { subject.call }.not_to change(Message, :count)
      end
    end
  end
end
