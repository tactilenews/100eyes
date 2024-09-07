# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization]) }

  describe 'GET /:organization_id/settings' do
    subject { -> { get organization_settings_path(organization, as: user) } }

    it 'renders successfully' do
      subject.call
      expect(response).to be_successful
    end
  end

  describe 'PATCH /:organization_id/settings' # TODO
end
