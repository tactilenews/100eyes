# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request, type: :model do
  let(:user) { User.create! }
  describe '::add_reply' do
    subject { -> { Request.add_reply(answer: 'The answer is 42.', user: user) } }
    it { should_not raise_error }
    it { should_not(change { Reply.count }) }

    describe 'given a recent request' do
      before(:each) do
        Request.create!(text: 'What is the answer to life the universe and everything?')
      end

      it { should change { Reply.count }.from(0).to(1) }
    end
  end
end
