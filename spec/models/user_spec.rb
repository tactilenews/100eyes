# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
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
