# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Settings', type: :request do
  describe 'GET /settings' do
    before { get settings_path(as: create(:user)) }
    subject { response }
    it { should have_http_status(:success) }
  end

  describe 'POST /settings' do
    subject { -> { post settings_path(as: create(:user)), params: params } }
    let(:params) { { setting: { project_name: 'Shiny new project' } } }

    it { should change { Setting.project_name }.to('Shiny new project') }
  end
end
