# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pendings', type: :request do
  describe 'GET /not_implemented' do
    it 'returns http success' do
      get '/pending/not_implemented'
      expect(response).to have_http_status(:success)
    end
  end
end
