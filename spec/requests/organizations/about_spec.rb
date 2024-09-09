# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'About', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization]) }

  describe 'GET /:organization_id/about' do
    subject { -> { get organization_about_path(organization, as: user) } }

    it 'renders successfully' do
      subject.call
      expect(response).to be_successful
    end
  end
end
