# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request, type: :model do
  let(:user) { User.create! }
  let(:request) do
    Request.new(
      text: 'What is the answer to life, the universe and everything?',
      hints: ['photo', 'confidential']
    )
  end

  describe 'hints' do
    subject { request.hints }
    it { should contain_exactly('photo', 'confidential') }
  end

  describe 'deliverable_message' do
    subject { request.deliverable_message }
    it { should include 'Hallo, die Redaktion hat eine neue Frage an dich!' }
    it { should include 'What is the answer to life, the universe and everything?' }
    it { should include 'Textbaustein für Foto' }
    it { should include 'Textbaustein für vertrauliche Informationen' }
    it { should_not include 'Textbaustein für Kontaktweitergabe' }
  end

  describe '::add_reply' do
    subject { -> { Request.add_reply(answer: 'The answer is 42.', user: user) } }
    it { should_not raise_error }
    it { should_not(change { Reply.count }) }

    describe 'given a recent request' do
      before(:each) { request.save! }
      it { should change { Reply.count }.from(0).to(1) }
    end
  end
end
