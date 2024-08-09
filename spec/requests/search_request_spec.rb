# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Searches', type: :request do
  let(:organization) { create(:organization) }

  describe 'GET /index' do
    it 'returns http success' do
      get organization_search_path(organization, as: create(:user))
      expect(response).to have_http_status(:success)
    end
  end
end
