# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Searches', type: :request do
  before { create(:organization) }

  describe 'GET /index' do
    it 'returns http success' do
      get search_path(as: create(:user))
      expect(response).to have_http_status(:success)
    end
  end
end
