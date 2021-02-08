# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mailer, type: :mailer do
  let(:text) { 'How do you do?' }
  let(:address) { 'test@example.org' }

  describe 'new_message_email' do
    let(:mail) do
      described_class.with(
        mail: {
          to: address
        },
        text: text
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
      subject { mail[:from].formatted }
      it { should eq(['TestingProject <100eyes-test-account@example.org>']) }
    end

    describe 'plaintext body' do
      subject { mail.text_part.body.decoded }

      it { should include I18n.t('mailer.unsubscribe.text') }
    end

    describe 'html body' do
      let(:text) { "How do you do?\n\nHere’s another line!" }
      subject { mail.html_part.body }

      it { should include I18n.t('mailer.unsubscribe.html') }

      it 'formats plain text' do
        subject.should have_css('p', exact_text: 'How do you do?')
        subject.should have_css('p', exact_text: 'Here’s another line!')
      end
    end
  end

  describe 'contributor_not_found_email' do
    let(:mail) { described_class.with(mail: { to: 'contributor@example.org' }, text: 'This is the @text').contributor_not_found_email }

    describe 'subject' do
      subject { mail.subject }
      it { should eq('Wir können Ihre E-Mail Adresse nicht zuordnen') }
    end

    describe 'body' do
      subject { mail.text_part.body.decoded }
      it { should include('This is the @text') }
    end
  end
end
