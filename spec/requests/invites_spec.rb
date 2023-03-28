# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Invites', type: :request do
  let(:user) { create(:user, organization: create(:organization)) }

  describe 'POST /invites' do
    subject { -> { post invites_path(as: user) } }

    it 'responds with a url with a jwt search query' do
      subject.call
      url = JSON.parse(response.body)['url']
      expect(url).to include('/onboarding?jwt=')
    end
  end
end
