# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailMessage do
  let(:email_message) { EmailMessage.new mail }
  let(:text_part) { 'This is a text body part' }

  describe '#text' do
    subject { -> { email_message.text } }
    let(:mail) do
      mail = Mail.new do |m|
        m.from 'user@example.org'
        m.to '100eyes@example.org'
        m.subject 'This is a test email'
      end
      mail.text_part = text_part
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
          m.body text_part
        end
      end
      it { should_not raise_error }
      it { expect(subject.call).to eq('This is a text body part') }

      describe '<html> tags present in text' do
        let(:text_part) { '<h1>This is a text body part</h1>' }
        it { expect(subject.call).to eq("\nThis is a text body part\n") }
      end
    end

    describe '<html> tags present in text' do
      let(:text_part) { '<h1>This is a text body part</h1>' }
      it { expect(subject.call).to eq("\nThis is a text body part\n") }
    end

    describe '<br> tags present in text' do
      let(:text_part) { 'First paragraph<br>Second paragraph' }

      it 'converts <br> to line breaks' do
        expect(subject.call).to eq("First paragraph\nSecond paragraph")
      end
    end

    describe '<p> tags present in text' do
      let(:text_part) { '<p>First paragraph</p><p>Second paragraph</p>' }

      it 'converts <p> to line breaks' do
        sanitized = <<~TEXT

          First paragraph

          Second paragraph
        TEXT

        expect(subject.call).to eq(sanitized)
      end
    end

    describe 'encoded special chars in text' do
      let(:text_part) { '&auml;&ouml;&uuml;' }

      it 'decodes encoded special chars' do
        expect(subject.call).to eq('äöü')
      end
    end

    describe '<a> tags present in text' do
      let(:text_part) { 'Have a look at my <a href="https://example.org">website</a>!' }

      it 'keeps link URLs' do
        expect(subject.call).to eq('Have a look at my website (https://example.org)!')
      end
    end

    describe '<a> tags without href attributes present in text' do
      let(:text_part) { 'Have a look at my <a>website</a>!' }

      it 'does not crash' do
        expect(subject.call).to eq('Have a look at my website!')
      end
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

  describe '#voice' do
    let(:mail) do
      mail = Mail.new
      mail.add_file Rails.root.join('README.md').to_s
      mail
    end
    subject { email_message.voice }
    it { should be_nil }
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
