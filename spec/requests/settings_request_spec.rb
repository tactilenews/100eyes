# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Settings', type: :request do
  describe 'GET /settings' do
    before { get settings_path, headers: auth_headers }
    subject { response }
    it { should have_http_status(:success) }
  end

  describe 'POST /settings' do
    subject { -> { post settings_path, params: params, headers: auth_headers } }
    let(:params) { { setting: { project_name: 'Shiny new project' } } }

    it { should change { Setting.project_name }.from('TestingProject').to('Shiny new project') }
  end
end
