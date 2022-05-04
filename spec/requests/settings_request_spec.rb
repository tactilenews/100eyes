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

    describe '`settting` params' do
      let(:params) { { setting: { project_name: 'Shiny new project' } } }

      it { will change { Setting.project_name }.to('Shiny new project') }
    end

    describe '`settting_files` params' do
      let(:params) do
        { setting: { project_name: 'Shiny new project' }, setting_files: { onboarding_logo: fixture_file_upload('profile_picture.jpg') } }
      end

      it { will change { Setting.onboarding_logo }.from(nil).to(instance_of(ActiveStorage::Blob)) }
    end
  end
end
