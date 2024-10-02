# frozen_string_literal: true

class AddTwilioContentSidsToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :twilio_content_sids, :jsonb, default: {
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
