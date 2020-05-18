# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request, type: :model do
  let(:user) { User.create! }

  let(:request) do
    Request.new(
      title: 'Hitchhiker’s Guide',
      text: 'What is the answer to life, the universe, and everything?',
      hints: ['photo', 'confidential']
    )
  end

  subject { request }

  it 'has title, text, and hints' do
    expect(subject.attributes.keys).to include('title', 'text', 'hints')
  end

  describe '.hints' do
    subject { Request.new(title: 'Example').hints }
    it { should match_array([]) }
  end

  describe '.plaintext' do
    subject { request.plaintext }

    it 'renders correct plaintext message' do
      expected  = "Hallo, die Redaktion hat eine neue Frage an dich:\n\n"
      expected += "What is the answer to life, the universe, and everything?\n\n"
      expected += "Textbaustein für Foto\n\n"
      expected += "Textbaustein für vertrauliche Informationen\n\n"
      expected += "Vielen Dank für deine Hilfe bei unserer Recherche!"

      expect(subject).to eql(expected)
    end

    describe 'without hints' do
      subject { Request.new(title: 'Example', text: 'Hello World!').plaintext }
    end
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
