# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessageMailer, type: :mailer do
  let(:text) { 'How do you do?' }
  let(:address) { 'test@example.org' }
  let(:broadcasted) { false }

  describe 'new_message_email' do
    let(:mail) do
      described_class.with(
        to: address,
        text: text,
        broadcasted: broadcasted
      ).new_message_email
    end

    describe 'subject' do
      subject { mail.subject }
      it { should eq('Die Redaktion hat eine neue Frage an dich') }
    end

    describe 'to' do
      subject { mail.to }
      it { should eq(['test@example.org']) }
    end

    describe 'from' do
      subject { mail.from }
      it { should eq(['100eyes-test-account@example.org']) }
    end
  end
end
