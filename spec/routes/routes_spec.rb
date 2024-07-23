# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Routes' do
  subject { Rails.application.routes.routes.map { |r| r.path.spec.to_s } }

  describe 'telegram_webhook' do
    before do
      Telegram.reset_bots
      Telegram::Bot::ClientStub.stub_all!(false)
    end

    after do
      Telegram::Bot::ClientStub.stub_all!(true)
      Telegram.reset_bots
    end

    context 'given a single organization' do
      let(:organization) do
        create(:organization, telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY', telegram_bot_username: 'TELEGRAM_BOT_USERNAME')
      end

      before do
        Telegram.bots_config = {
          organization.id => {
            # must be the filtered values from /spec/vcr_setup.rb
            token: organization.telegram_bot_api_key,
            username: organization.telegram_bot_username
          }
        }
        Rails.application.reload_routes!
      end

      subject { Rails.application.routes.routes.map { |r| r.path.spec.to_s } }
      # Get the token hash with: Telegram::Bot::RoutesHelper.token_hash('TELEGRAM_BOT_API_KEY')
      it { is_expected.to include('/telegram/wjHTUUfn99RvU8m7ebIkED-MWu4') }
    end

    context 'given a second organization' do
      let(:organization) do
        create(:organization, telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY', telegram_bot_username: 'TELEGRAM_BOT_USERNAME')
      end

      let(:another) do
        create(:organization, telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY_2', telegram_bot_username: 'TELEGRAM_BOT_USERNAME_2')
      end

      before do
        Telegram.bots_config = {
          organization.id => {
            # must be the filtered values from /spec/vcr_setup.rb
            token: organization.telegram_bot_api_key,
            username: organization.telegram_bot_username
          },
          another.id => {
            # must be the filtered values from /spec/vcr_setup.rb
            token: another.telegram_bot_api_key,
            username: another.telegram_bot_username
          }
        }
        Rails.application.reload_routes!
      end

      it { is_expected.to include('/telegram/wjHTUUfn99RvU8m7ebIkED-MWu4') }
      it { is_expected.to include('/telegram/iSRjtX9tTE5VggXKyPb5S5PdzLo') }
    end
  end
end
