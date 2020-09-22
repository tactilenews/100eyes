# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FacebookMessage do
  let(:facebook_message) { FacebookMessage.new message }

  describe '#text' do
    subject { facebook_message.text }
    describe 'given a message with a `text` attribute' do
      let(:message) { instance_double('FakeMessage', text: 'It is a truth universally acknowledged.') }
      it { should eq('It is a truth universally acknowledged.') }
    end
  end

  describe '.unknown_content' do
    subject { facebook_message.unknown_content }
    let(:message) { instance_double('FakeMessage', text: 'It is a truth universally acknowledged.') }
    it { should be(false) }
  end
end
