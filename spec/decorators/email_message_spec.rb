# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailMessage do
  let(:email_message) { EmailMessage.new mail }

  describe '#text' do
    subject { -> { email_message.text } }
    let(:mail) do
      mail = Mail.new do |m|
        m.from 'user@example.org'
        m.to '100eyes@example.org'
        m.subject 'This is a test email'
      end
      mail.text_part = 'This is a text body part'
      mail
    end

    it { should_not raise_error }
    it { expect(subject.call).to eq('This is a text body part') }

    describe 'given no multipart' do
      let(:mail) do
        Mail.new do |m|
          m.from 'user@example.org'
          m.to '100eyes@example.org'
          m.subject 'This is a test email'
          m.body 'This is a body'
        end
      end
      it { should_not raise_error }
      it { expect(subject.call).to eq('This is a body') }
    end
  end

  describe '#message' do
    describe '.unknown_content' do
      subject { email_message.message.unknown_content }
      describe 'given a mail attachment' do
        describe 'with a .txt multipart' do
          let(:mail) do
            mail = Mail.new do |m|
              m.from 'user@example.org'
              m.to '100eyes@example.org'
              m.subject 'This is a test email'
            end
            mail.add_file(Rails.root.join('README.md').to_s)
            mail
          end
          it { should be(true) }
        end

        describe 'with a .png multipart' do
          let(:mail) do
            mail = Mail.new do |m|
              m.from 'user@example.org'
              m.to '100eyes@example.org'
              m.subject 'This is a test email'
            end
            mail.add_file(Rails.root.join('example-image.png').to_s)
            mail
          end
          it { should be(false) }
        end
      end
    end
  end

  describe '#photos' do
    subject { email_message.photos }
    describe 'given a file attachment' do
      let(:mail) do
        mail = Mail.new
        mail.add_file Rails.root.join('README.md').to_s
        mail
      end
      it { should be_empty }
    end

    describe 'given an image attachment' do
      let(:mail) do
        mail = Mail.new
        mail.add_file Rails.root.join('example-image.png').to_s
        mail
      end
      it { should_not be_empty }
      it { should all be_a(Photo) }
    end
  end
end
