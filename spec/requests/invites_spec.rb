# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Invites', type: :request do
  let(:user) { create(:user) }

  describe 'POST /invites' do
    subject { -> { post invites_path(as: user) } }

    context 'without log-in' do
      let(:user) { nil }
      it 'is unsuccessful' do
        subject.call
        expect(response).not_to be_successful
      end
    end

    context 'as a logged-in user' do
      it 'responds with a url with a jwt search query' do
        subject.call
        url = JSON.parse(response.body)['url']
        expect(url).to include('/onboarding?jwt=')
      end
    end
  end
end
