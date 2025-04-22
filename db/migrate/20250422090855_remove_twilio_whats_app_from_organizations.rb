# frozen_string_literal: true

class RemoveTwilioWhatsAppFromOrganizations < ActiveRecord::Migration[6.1]
  def change
    change_table :organizations, bulk: true do |t|
      t.remove :twilio_api_key_sid, type: :string
      t.remove :encrypted_twilio_api_key_secret, type: :string
      t.remove :encrypted_twilio_api_key_secret_iv, type: :string
      t.remove :twilio_account_sid, type: :string
      t.remove :twilio_content_sids, type: :jsonb, default: {
        new_request_morning1: '',
        new_request_morning2: '',
        new_request_morning3: '',
        new_request_day1: '',
        new_request_day2: '',
        new_request_day3: '',
        new_request_evening1: '',
        new_request_evening2: '',
        new_request_evening3: '',
        new_request_night1: '',
        new_request_night2: '',
        new_request_night3: ''
      }
    end
  end
end
