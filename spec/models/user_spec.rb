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

  let(:user) { User.create! }
  describe '#respond' do
    it 'ignores feedback without request' do
      expect { user.respond_feedback(answer: 'some answer') }.not_to raise_error
      expect { user.respond_feedback(answer: 'some answer') }.not_to(change { Reply.count })
    end

    describe 'given feedback was requested on a recent request' do
      before(:each) do
        Request.create!(text: "Hey what's up?")
      end

      it 'saves user feedback along with a request' do
        expect { user.respond_feedback(answer: 'some answer') }.to(change { Reply.count }.from(0).to(1))
      end
    end
  end
end
