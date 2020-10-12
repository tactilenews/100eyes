# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Onboarding', type: :request do
  let(:user) { create(:user) }

  describe 'GET /index' do
    it 'should be successful' do
      get onboarding_path
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    let(:attrs) do
      {
        first_name: 'Perry',
        last_name: 'Schnabeltier',
        email: 'enemy@doofenshmirgtz.org'
      }
    end

    subject { -> { post onboarding_path, params: { user: attrs } } }

    it 'creates user' do
      expect { subject.call }.to change(User, :count).by(1)

      user = User.first
      expect(user.first_name).to eq('Perry')
      expect(user.last_name).to eq('Schnabeltier')
      expect(user.email).to eq('enemy@doofenshmirgtz.org')
    end

    it 'redirects to success page' do
      subject.call
      expect(response).to redirect_to(onboarding_success_path)
    end
  end
end
