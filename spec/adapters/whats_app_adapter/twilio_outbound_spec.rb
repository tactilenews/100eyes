# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WhatsAppAdapter::TwilioOutbound do
  let(:adapter) { described_class.new }
  let(:message) { create(:message, text: 'WhatsApp as a channel is great, no?', broadcasted: true, recipient: contributor) }
  let(:organization) do
    create(:organization, onboarding_success_heading: onboarding_success_heading, onboarding_success_text: onboarding_success_text)
  end
  let(:contributor) { create(:contributor, email: nil) }
  let(:onboarding_success_heading) { 'Thanks for onboarding' }
  let(:onboarding_success_text) { 'We will start sending messages soon.' }

  describe '::send_welcome_message!' do
    let(:expected_job_args) do
      { organization_id: organization.id, contributor_id: contributor.id,
        text: ["*#{onboarding_success_heading}*", onboarding_success_text].join("\n\n") }
    end
    subject { -> { described_class.send_welcome_message!(contributor, organization) } }
    before do
      message # we don't count the extra ::send here
    end

    it { should_not enqueue_job(WhatsAppAdapter::TwilioOutbound::Text) }

    context 'contributor has a phone number' do
      let(:contributor) do
        create(
          :contributor,
          whats_app_phone_number: '+491511234567',
          email: nil
        )
      end

      it { should enqueue_job(WhatsAppAdapter::TwilioOutbound::Text).with(expected_job_args) }
    end
  end

  describe '::send!' do
    subject { -> { described_class.send!(message) } }
    before { message } # we don't count the extra ::send here

    context '`whats_app_phone_number` blank' do
      it { should_not enqueue_job(WhatsAppAdapter::TwilioOutbound::Text) }
    end

    context 'given a WhatsApp contributor' do
      let(:contributor) do
        create(
          :contributor,
          email: nil,
          whats_app_phone_number: '+491511234567'
        )
      end

      describe 'contributor has not sent a message within 24 hours' do
        it 'enqueues the Text job with WhatsApp template' do
          expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::TwilioOutbound::Template).on_queue('default').with do |params|
                                       expect(params[:organization_id]).to eq(message.organization.id)
                                       expect(params[:contributor_id]).to eq(contributor.id)
                                       expect(params[:content_sid]).to be_kind_of(String)
                                       expect(params[:message]).to eq(message)
                                     end)
        end
      end

      describe 'contributor has responded to a template' do
        before { contributor.update(whats_app_message_template_responded_at: Time.current) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::TwilioOutbound::Text).on_queue('default').with do |params|
            expect(params[:contributor_id]).to eq(contributor.id)
            expect(params[:text]).to eq(message.text)
            expect(params[:message]).to eq(message)
          end)
        end
      end

      describe 'contributor has sent a reply within 24 hours' do
        before { create(:message, sender: contributor) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::TwilioOutbound::Text).on_queue('default').with do |params|
            expect(params[:contributor_id]).to eq(contributor.id)
            expect(params[:text]).to eq(message.text)
            expect(params[:message]).to eq(message)
          end)
        end
      end

      describe 'message with files' do
        before { create(:file, message: message) }

        context 'contributor has not sent a message within 24 hours' do
          it 'enqueues the Text job with WhatsApp template' do
            expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::TwilioOutbound::Template).on_queue('default').with do |params|
              expect(params[:organization_id]).to eq(message.organization.id)
              expect(params[:contributor_id]).to eq(contributor.id)
              expect(params[:content_sid]).to be_kind_of(String)
              expect(params[:message]).to eq(message)
            end)
          end
        end

        context 'contributor has sent a reply within 24 hours' do
          before { create(:message, sender: contributor) }
          it 'enqueues a File job with file, contributor, text' do
            expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::TwilioOutbound::File).on_queue('default').with do |params|
              expect(params[:message]).to eq(message)
              expect(params[:contributor_id]).to eq(contributor.id)
            end)
          end
        end
      end
    end
  end

  describe '::freeform_message_permitted?(recipient)' do
    subject { described_class.send(:freeform_message_permitted?, contributor) }

    describe 'template message' do
      context  'contributor has responded' do
        before { contributor.update(whats_app_message_template_responded_at: 1.second.ago) }

        it { is_expected.to eq(true) }
      end

      context 'contributor has not responded, and has no messages within 24 hours' do
        it { is_expected.to eq(false) }
      end
    end

    describe 'message from contributor within 24 hours' do
      context 'has been received' do
        before { create(:message, sender: contributor) }

        it { is_expected.to eq(true) }
      end

      context 'has not been received' do
        it { is_expected.to eq(false) }
      end
    end
  end
end
