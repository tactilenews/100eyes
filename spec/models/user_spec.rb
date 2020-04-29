# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#name=' do
    let(:user) { User.new(first_name: 'John', last_name: 'Doe') }
    subject { -> { user.name = 'Till Prochaska' } }
    it { should change { user.first_name }.from('John').to('Till') }
    it { should change { user.last_name }.from('Doe').to('Prochaska') }
  end

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
