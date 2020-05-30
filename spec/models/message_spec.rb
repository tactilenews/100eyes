# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  it 'is by default sorted in reverse chronological order' do
    oldest_message = create(:message, created_at: 2.hours.ago)
    newest_message = create(:message, created_at: 1.hour.ago)

    expect(described_class.first).to eq(newest_message)
    expect(described_class.last).to eq(oldest_message)
  end
end
