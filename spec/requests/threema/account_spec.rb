# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Threema::Accounts', type: :request do
  describe 'GET /threema/credits' do
    let(:action) { get(threema_credits_path(as: create(:user))) }
    let(:account) { instance_double(Threema::Account) }

    subject { action && JSON.parse(response.body).transform_keys(&:to_sym) }

    context 'with valid threema credentials' do
      before do
        allow(Threema::Account).to receive(:new).and_return(account)
        allow(account).to receive(:credits).and_return(4711)
      end
      it { should eq(credits: 4711) }
    end

    context 'without threema credentials' do
      before do
        allow(Threema::Account).to receive(:new).and_return(account)
        allow(account).to receive(:credits).and_raise(Unauthorized)
      end
      it { should eq(credits: nil) }
    end
  end
end
