# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/contributors' do
  let(:user) { create(:user, organization: organization) }
  let(:contact_person) { create(:user) }
  let(:organization) { create(:organization, contact_person: contact_person) }

  before do
    organization.users << contact_person
    organization.save
  end

  describe 'GET /index' do
    it 'should be successful' do
      get profile_url(as: user)
      expect(response).to be_successful
    end
  end
end
