# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ThreeSixtyDialog::Api do
  let(:api) { described_class.new }

  describe '#perform_request' do
    let(:url) { URI.parse('https://www.example.com') }
    let(:request) { Net::HTTP::Post.new(url) }

    before do
      allow(ErrorNotifier).to receive(:report)
    end

    describe 'http resonse code' do
      describe '201' do
        before(:each) do
          stub_request(:post, url).to_return(status: 201)
        end
        specify { expect { |block| api.perform_request(request, &block) }.to yield_control }
      end

      describe '401' do
        before(:each) do
          stub_request(:post, url).to_return(status: 401)
        end

        specify { expect { |block| api.perform_request(request, &block) }.not_to yield_control }
      end
    end
  end

  describe '#partner_token' do
    let(:url) { URI.parse('https://hub.360dialog.io/api/v2/token') }
    before(:each) do
      allow(Setting).to receive(:three_sixty_dialog_partner_username).and_return('alerts@dialog.click')
      allow(Setting).to receive(:three_sixty_dialog_partner_password).and_return('*******************')

      body = { access_token: '<access-token>' }.to_json
      stub_request(:post, url).to_return(status: 200, body: body)
    end

    it 'lazy loads partner token' do
      expect(api.partner_token).to eq('<access-token>')
    end
  end

  describe '#client_api_key' do
    it 'returns an api client key for a given channel' do
      skip
    end
  end
end
