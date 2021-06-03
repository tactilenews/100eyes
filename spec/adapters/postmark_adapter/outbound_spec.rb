# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostmarkAdapter::Outbound, type: :mailer do
  describe 'with(params)' do
    describe '#bounce_email' do
      let(:bounce_email) do
        described_class.with(
          mail: {
            to: 'contributor@example.org',
            subject: I18n.t('adapter.postmark.contributor_not_found_email.subject')
          },
          text: 'This is the @text'
        ).bounce_email
      end

      describe 'subject' do
        subject { bounce_email.subject }
        it { should eq('Wir können Ihre E-Mail Adresse nicht zuordnen') }
      end

      describe 'body' do
        subject { bounce_email.text_part.body.decoded }
        it { should include('This is the @text') }
      end
    end
  end

  describe 'with(message: message)' do
    let(:adapter) { described_class.with(message: message) }
    let(:request) { create(:request, id: 4711) }
    let(:recipient) { create(:contributor, email: email_address) }
    let(:email_address) { 'recipient@example.org' }
    let(:message) { create(:message, id: 42, text: text, recipient: recipient, broadcasted: broadcasted, request: request) }
    let(:text) { 'How do you do?' }
    let(:broadcasted) { false }
    before { allow(Setting).to receive(:application_host).and_return('example.org') }

    describe '#message_email' do
      let(:message_email) { adapter.message_email }

      describe 'to' do
        subject { message_email.to }
        it { should eq(['recipient@example.org']) }
      end

      describe 'from' do
        before do
          allow(Setting).to receive(:email_from_address).and_return('100eyes-test-account@example.org')
          allow(Setting).to receive(:project_name).and_return('TestingProject')
        end

        subject { message_email[:from].formatted }
        it { should eq(['TestingProject <100eyes-test-account@example.org>']) }
      end

      describe 'plaintext body' do
        subject { message_email.text_part.body.decoded }

        it { should include I18n.t('mailer.unsubscribe.text') }
      end

      describe 'html body' do
        let(:text) { "How do you do?\n\nHere’s another line!" }
        subject { message_email.html_part.body }

        it { should include I18n.t('mailer.unsubscribe.html') }

        it 'formats plain text' do
          expect(subject).to have_css('p', exact_text: 'How do you do?')
          expect(subject).to have_css('p', exact_text: 'Here’s another line!')
        end
      end

      describe '#message_stream' do
        subject { message_email.message_stream }

        it { should eq(Setting.postmark_transactional_stream) }

        context 'given message is broadcasted as part of a request' do
          let(:broadcasted) { true }
          it { should eq(Setting.postmark_broadcasts_stream) }
        end
      end

      describe '#subject' do
        subject { message_email.subject }

        it { should eq('Re: Die Redaktion hat eine neue Frage') }

        context 'if message is broadcasted' do
          let(:broadcasted) { true }
          it { should eq('Die Redaktion hat eine neue Frage') }
        end
      end

      describe '#message_id' do
        subject { message_email.message_id }

        it { is_expected.to eq('request/4711/message/42@example.org') }

        context 'if message is broadcasted' do
          let(:broadcasted) { true }
          subject { message_email.message_id }
          it { is_expected.to eq('request/4711@example.org') }
        end
      end

      describe '#references' do
        subject { message_email.references }

        it { is_expected.to eq('request/4711@example.org') }

        context 'if message is broadcasted' do
          let(:broadcasted) { true }
          subject { message_email.references }
          it { is_expected.to eq(nil) }
        end
      end
    end

    describe '::send!' do
      subject { described_class.send!(message) }
      let(:message) { create(:message, text: 'How do you do?', broadcasted: true, recipient: contributor) }
      let(:contributor) { create(:contributor, email: 'contributor@example.org') }

      it 'enqueues a Mailer' do
        expect { subject }.to have_enqueued_job.on_queue('default').with(
          'PostmarkAdapter::Outbound',
          'message_email',
          'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
          {
            params: { message: message },
            args: []
          }
        )
      end
    end
  end
end
