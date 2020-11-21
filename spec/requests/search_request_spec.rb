# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Searches', type: :request do
  describe 'GET /index' do
    before { login_as(create(:user)) }

    it 'returns http success' do
      get '/search'
      expect(response).to have_http_status(:success)
    end
  end
end
