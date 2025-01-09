# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostmarkAdapter::Outbound, type: :mailer do
  describe 'with(params)' do
    describe '#bounce_email' do
      let(:bounce_email) do
        described_class.with(
          organization: create(:organization),
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

    describe '#welcome_email' do
      let(:organization) do
        create(:organization, onboarding_success_heading: 'Welcome new contributor!',
                              onboarding_success_text: 'You onboarded successfully.')
      end

      let(:contributor) { create(:contributor, email: 'contributor@example.org') }
      let(:welcome_email) do
        described_class.with(contributor: contributor, organization: organization).welcome_email
      end

      describe 'subject' do
        subject { welcome_email.subject }
        it { should eq('Welcome new contributor!') }
      end

      describe 'body' do
        subject { welcome_email.text_part.body.decoded }
        it { should include("Welcome new contributor!\r\nYou onboarded successfully.") }
      end
    end
  end

  describe 'with(message: message, organization: message.organization)' do
    let(:adapter) { described_class.with(message: message, organization: message.organization) }
    let!(:organization) { create(:organization, email_from_address: '100eyes-test-account@example.org', project_name: 'TestingProject') }
    let(:request) { create(:request, id: 4711, organization: organization) }
    let(:recipient) { create(:contributor, email: email_address) }
    let(:email_address) { 'recipient@example.org' }
    let(:message) { create(:message, id: 42, text: text, recipient: recipient, broadcasted: broadcasted, request: request) }
    let(:text) { 'How do you do?' }
    let(:broadcasted) { false }

    describe '#message_email' do
      let(:message_email) { adapter.message_email }

      describe 'to' do
        subject { message_email.to }
        it { should eq(['recipient@example.org']) }
      end

      describe 'from' do
        subject { message_email[:from].formatted }
        it { should eq(['TestingProject <100eyes-test-account@example.org>']) }

        context 'with a comma / list separator in the project name' do
          before do
            organization.update(project_name: 'TestingProject, with a comma!')
          end

          it { should eq(['"TestingProject, with a comma!" <100eyes-test-account@example.org>']) }
        end
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

        it { should eq('outbound') }

        context 'given message is broadcasted as part of a request' do
          let(:broadcasted) { true }
          it { should eq('broadcasts') }
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

      describe '#attachments' do
        let(:message) { create(:message, :with_file, text: text, recipient: recipient, broadcasted: broadcasted, request: request) }

        context 'if message is broadcast' do
          let(:broadcasted) { true }
          subject { message_email.attachments }

          it { is_expected.not_to be_empty }

          it 'attaches file with its filename' do
            expect(subject.first.filename).to eq(message.files.first.attachment.filename.to_s)
          end

          it 'is attached inline' do
            expect(subject.first).to be_inline
          end
        end

        context 'if message is not broadcast, ie a reply message' do
          let(:broadcasted) { false }
          subject { message_email.attachments }

          it { is_expected.to be_empty }
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
            params: { message: message, organization: message.organization },
            args: []
          }
        )
      end
    end

    describe '::send_business_plan_upgraded_message!' do
      subject { described_class.send_business_plan_upgraded_message!(admin, organization) }

      context 'no admin' do
        let(:admin) { nil }
        let(:organization) { build(:organization) }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'no organization' do
        let(:admin) { build(:user, admin: true) }
        let(:organization) { nil }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'user, not admin' do
        let(:admin) { build(:user) }
        let(:organization) { build(:organization) }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'with an admin and organization' do
        let(:admin) { create(:user, admin: true) }
        let(:organization) { create(:organization) }

        it 'enqueues a Mailer' do
          expect { subject }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'business_plan_upgraded_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: admin, organization: organization, price_per_month_with_discount: kind_of(String) },
              args: []
            }
          )
        end
      end
    end

    describe '::send_user_count_exceeds_plan_limit_message!' do
      subject { described_class.send_user_count_exceeds_plan_limit_message!(admin, organization) }

      context 'no admin' do
        let(:admin) { nil }
        let(:organization) { build(:organization) }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'no organization' do
        let(:admin) { build(:user, admin: true) }
        let(:organization) { nil }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'user, not admin' do
        let(:admin) { build(:user) }
        let(:organization) { build(:organization) }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'with an admin and organization' do
        let(:admin) { create(:user, admin: true) }
        let(:organization) { create(:organization) }

        it 'enqueues a Mailer' do
          expect { subject }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'user_count_exceeds_plan_limit_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: admin, organization: organization },
              args: []
            }
          )
        end
      end
    end

    describe '::contributor_marked_as_inactive!' do
      subject { described_class.contributor_marked_as_inactive!(admin, contributor, organization) }

      context 'no admin' do
        let(:admin) { nil }
        let(:contributor) { create(:contributor, organization: organization) }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'no contributor' do
        let(:admin) { build(:user, admin: true) }
        let(:contributor) { nil }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'user without an admin role' do
        let(:admin) { build(:user) }
        let(:contributor) { create(:contributor, organization: organization) }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'admin email equals contributor email' do
        let(:admin) { create(:user, admin: true, email: 'my-email@example.org') }
        let(:contributor) { create(:contributor, email: 'my-email@example.org', organization: organization) }

        it 'does not enqueue a Mailer' do
          expect { subject }.not_to have_enqueued_job
        end
      end

      context 'with an admin and contributor without the same email address' do
        let(:admin) { create(:user, admin: true, email: 'admin@example.org') }
        let(:contributor) { create(:contributor, email: 'contributor@example.org') }

        it 'enqueues a Mailer' do
          expect { subject }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'contributor_marked_as_inactive_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: admin, contributor: contributor, organization: organization },
              args: []
            }
          )
        end
      end
    end
  end
end
