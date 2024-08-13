# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Invites', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization]) }

  describe 'POST /invites' do
    subject { -> { post organization_invites_path(organization, as: user) } }

    it 'responds with a url with a jwt search query' do
      subject.call
      url = JSON.parse(response.body)['url']
      expect(url).to include('/onboarding?jwt=')
    end
  end
end
