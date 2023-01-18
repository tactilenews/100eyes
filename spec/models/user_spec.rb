# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let(:user) { create(:user) }
  subject { user.update(otp_enabled: false) }

  describe '#reset_otp' do
    it 'updates `otp_secret_key`' do
      expect { subject }.to change(user, :otp_secret_key)
    end

    context 'updating other attribute' do
      subject { user.update(first_name: 'Keep my secret', last_name: 'Please') }

      it ' does not update otp_secret_key' do
        expect { subject }.not_to change(user, :otp_secret_key)
      end
    end
  end
end
