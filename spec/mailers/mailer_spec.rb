# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mailer, type: :mailer do
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
      it { should eq('Die Redaktion hat eine neue Frage') }
    end

    describe 'to' do
      subject { mail.to }
      it { should eq(['test@example.org']) }
    end

    describe 'from' do
      subject { mail.from }
      it { should eq(['100eyes-test-account@example.org']) }
    end

    describe 'body' do
      subject { mail.text_part.body.decoded }
      it { should include I18n.t('mailer.unsubscribe.text') }
    end

    describe 'message_stream' do
      subject { mail.message_stream }
      it { should eq(Setting.postmark_transactional_stream) }

      describe 'with broadcasted=true' do
        let(:broadcasted) { true }
        it { should eq(Setting.postmark_broadcasts_stream) }
      end
    end
  end

  describe 'new_question_email' do
    let(:mail) { described_class.with(email: 'user@example.org').user_not_found_email }

    describe 'subject' do
      subject { mail.subject }
      it { should eq('Wir können deine E-Mail Adresse nicht zuordnen') }
    end

    describe 'body' do
      subject { mail.text_part.body.decoded }
      it { should include('Wir können deine E-Mail Adresse leider keinem unserer Benutzerprofile zuordnen.') }
    end
  end
end
