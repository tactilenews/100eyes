# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/contributors' do
  let(:user) { create(:user) }

  describe 'GET /index' do
    it 'should be successful' do
      get profile_url(as: user)
      expect(response).to be_successful
    end
  end
end
