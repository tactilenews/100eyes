# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WhatsAppAdapter::Outbound do
  let(:adapter) { described_class.new }
  let(:message) { create(:message, text: 'WhatsApp as a channel is great, no?', broadcasted: true, recipient: contributor) }
  let(:contributor) { create(:contributor, email: nil) }

  describe '::send_welcome_message!' do
    let(:expected_job_args) do
      { recipient: contributor, text: I18n.t('adapter.whats_app.welcome_message', project_name: Setting.project_name) }
    end
    subject { -> { described_class.send_welcome_message!(contributor) } }
    before { message } # we don't count the extra ::send here

    it { should_not enqueue_job(described_class::Text) }

    context 'contributor has a phone number' do
      let(:contributor) do
        create(
          :contributor,
          whats_app_phone_number: '+491511234567',
          email: nil
        )
      end

      it { should enqueue_job(described_class::Text).with(expected_job_args) }
    end
  end

  describe '::send!' do
    subject { -> { described_class.send!(message) } }
    before { message } # we don't count the extra ::send here

    context '`whats_app_phone_number` blank' do
      it { should_not enqueue_job(described_class::Text) }
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
          expect { subject.call }.to(have_enqueued_job(described_class::Text).on_queue('default').with do |params|
                                       expect(params[:recipient]).to eq(contributor)
                                       expect(params[:text]).to include(contributor.first_name)
                                       expect(params[:text]).to include(message.request.title)
                                     end)
        end
      end

      describe 'contributor has responded to a template' do
        before { contributor.update(whats_app_message_template_responded_at: Time.current) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to(have_enqueued_job(described_class::Text).on_queue('default').with do |params|
            expect(params[:recipient]).to eq(contributor)
            expect(params[:text]).to eq(message.text)
          end)
        end
      end

      describe 'contributor has sent a reply within 24 hours with no template being sent' do
        before { create(:message, sender: contributor) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to(have_enqueued_job(described_class::Text).on_queue('default').with do |params|
            expect(params[:recipient]).to eq(contributor)
            expect(params[:text]).to eq(message.text)
          end)
        end
      end

      describe 'message with files' do
        let(:file) { create(:file) }
        before { message.update(files: [file]) }

        context 'contributor has not sent a message within 24 hours' do
          it 'enqueues the Text job with WhatsApp template' do
            expect { subject.call }.to(have_enqueued_job(described_class::Text).on_queue('default').with do |params|
              expect(params[:recipient]).to eq(contributor)
              expect(params[:text]).to include(contributor.first_name)
              expect(params[:text]).to include(message.request.title)
            end)
          end
        end

        context 'contributor has sent a reply within 24 hours' do
          before { create(:message, sender: contributor) }
          it 'enqueues a File job with file, contributor, text' do
            expect { subject.call }.to(have_enqueued_job(described_class::File).on_queue('default').with do |params|
              expect(params[:file]).to eq(message.files.first)
              expect(params[:recipient]).to eq(contributor)
              expect(params[:text]).to eq(message.text)
            end)
          end
        end
      end
    end
  end

  describe '::freeform_message_permitted?(recipient)' do
    subject { described_class.freeform_message_permitted?(contributor) }

    describe 'template message' do
      context  'contributor has responded' do
        before { contributor.update(whats_app_message_template_responded_at: 1.second.ago) }

        it { is_expected.to eq(true) }
      end

      context 'contributor has not responded' do
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