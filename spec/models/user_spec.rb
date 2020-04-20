# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#email' do
    it 'must be unique' do
      User.create!(email: 'user@example.org')
      expect { User.create!(email: 'user@example.org') }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#telegram_id' do
    it 'must be unique' do
      User.create!(telegram_id: 1)
      expect { User.create!(telegram_id: 1) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
