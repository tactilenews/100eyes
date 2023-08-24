# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialogOutbound do
  let(:adapter) { described_class.new }
  let!(:message) { create(:message, text: '360dialog is great!', broadcasted: true, recipient: contributor) }
  let(:contributor) { create(:contributor, email: nil) }
  let(:new_request_payload) do
    {
      recipient_type: 'individual',
      to: contributor.whats_app_phone_number.split('+').last,
      type: 'template',
      template: {
        namespace: Setting.three_sixty_dialog_whats_app_template_namespace,
        language: {
          policy: 'deterministic',
          code: 'de'
        },
        name: kind_of(String),
        components: [
          {
            type: 'body',
            parameters: [
              {
                type: 'text',
                text: contributor.first_name
              },
              {
                type: 'text',
                text: message.request.title
              }
            ]
          }
        ]
      }
    }
  end
  let(:text_payload) do
    {
      recipient_type: 'individual',
      to: contributor.whats_app_phone_number.split('+').last,
      type: 'text',
      text: {
        body: message.text
      }
    }
  end

  describe '::send!' do
    subject { -> { described_class.send!(message) } }
    before { message } # we don't count the extra ::send here

    context '`whats_app_phone_number` blank' do
      it { should_not enqueue_job(WhatsAppAdapter::Outbound::Text) }
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
          expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).on_queue('default').with do |params|
                                       expect(params[:payload]).to include(new_request_payload)
                                     end)
        end
      end

      describe 'contributor has responded to a template' do
        before { contributor.update(whats_app_message_template_responded_at: Time.current) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).on_queue('default').with do |params|
            expect(params[:payload]).to eq(text_payload)
          end)
        end
      end

      describe 'contributor has sent a reply within 24 hours' do
        before { create(:message, sender: contributor) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).on_queue('default').with do |params|
            expect(params[:payload]).to eq(text_payload)
          end)
        end
      end

      describe 'message with files' do
        let(:file) { create(:file) }
        before { message.update(files: [file]) }

        context 'contributor has not sent a message within 24 hours' do
          it 'enqueues the Text job with WhatsApp template' do
            expect do
              subject.call
            end.to(have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).on_queue('default').with do |params|
                     expect(params[:payload]).to include(new_request_payload)
                   end)
          end
        end

        context 'contributor has sent a reply within 24 hours' do
          before { create(:message, sender: contributor) }
          it 'enqueues a File job with file, contributor, text' do
            expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::UploadFile).on_queue('default').with do |params|
              expect(params[:message_id]).to eq(message.id)
            end)
          end
        end
      end
    end
  end
end
