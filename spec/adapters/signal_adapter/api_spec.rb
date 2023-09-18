# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SignalAdapter::Api do
  let(:api) { described_class }

  describe '#perform_request' do
    let(:uri) { URI.parse('http://signal:8080/v2/send') }
    let(:request) { Net::HTTP::Post.new(uri) }

    before do
      allow(ErrorNotifier).to receive(:report)
    end

    describe 'http response code' do
      describe '200' do
        before(:each) do
          stub_request(:post, uri).to_return(status: 200)
        end
        specify { expect { |block| api.perform_request(request, &block) }.to yield_control }

        describe 'ErrorNotifier' do
          subject { ErrorNotifier }
          before { api.perform_request(request) }
          it { should_not have_received(:report) }
        end
      end

      describe '400' do
        before(:each) do
          stub_request(:post, uri).to_return(status: 400, body: { error: 'Ouch!' }.to_json)
        end

        specify { expect { |block| api.perform_request(request, &block) }.not_to yield_control }

        describe 'ErrorNotifier' do
          subject { ErrorNotifier }
          before { api.perform_request(request) }
          it { should have_received(:report) }
        end
      end
    end
  end
end
