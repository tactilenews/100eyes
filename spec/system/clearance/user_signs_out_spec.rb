# frozen_string_literal: true

require 'rails_helper'
require 'support/system/clearance_helpers'

RSpec.describe 'User signs out' do
  scenario 'signs out' do
    sign_in
    sign_out

    expect_user_to_be_signed_out
  end
end
