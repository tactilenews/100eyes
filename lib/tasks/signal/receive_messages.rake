# frozen_string_literal: true

namespace :signal do
  desc 'GET signal messages for our `signal_server_phone_number` from signal-rest-cli endpoint'
  task receive_messages: :environment do
    SignalAdapter::ReceivePollingJob.perform_later
  end
end
