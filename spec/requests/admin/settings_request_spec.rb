# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Settings', type: :request do
  describe 'GET /admin/settings' do
    before { get admin_settings_path, headers: auth_headers }
    subject { response }
    it { should have_http_status(:success) }
  end

  describe 'POST /admin/settings' do
    subject { -> { post admin_settings_path, params: params, headers: auth_headers } }
    let(:params) { { setting: { project_name: 'Shiny new project' } } }

    it { should change { Setting.project_name }.from('TestingProject').to('Shiny new project') }
  end
end
