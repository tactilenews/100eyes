# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reply, type: :model do
  it 'is by default sorted in reverse chronological order' do
    oldest_reply = create(:reply, created_at: 2.hours.ago)
    newest_reply = create(:reply, created_at: 1.hour.ago)

    expect(described_class.first).to eq(newest_reply)
    expect(described_class.last).to eq(oldest_reply)
  end
end
