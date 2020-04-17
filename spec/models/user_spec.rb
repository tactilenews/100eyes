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
    it 'ignores feedback without issue' do
      expect { user.respond_feedback(answer: 'some answer') }.not_to raise_error
      expect { user.respond_feedback(answer: 'some answer') }.not_to(change { Feedback.count })
    end

    describe 'given feedback was requested on a recent issue' do
      before(:each) do
        Issue.create!(text: "Hey what's up?")
      end

      it 'saves user feedback along with an issue' do
        expect { user.respond_feedback(answer: 'some answer') }.to(change { Feedback.count }.from(0).to(1))
      end
    end
  end
end
