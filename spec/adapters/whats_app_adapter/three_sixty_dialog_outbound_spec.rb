# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialogOutbound do
  let(:adapter) { described_class.new }
  let(:organization) do
    create(:organization, project_name: 'Great project')
  end
  let!(:message) do
    create(:message, :outbound, text: '360dialog is great!', broadcasted: true, recipient: contributor,
                                request: create(:request, organization: organization))
  end
  let(:contributor) { create(:contributor, organization: organization) }
  let(:new_request_payload) do
    {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: contributor.whats_app_phone_number.split('+').last,
      type: 'template',
      template: {
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
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: contributor.whats_app_phone_number.split('+').last,
      type: 'text',
      text: {
        body: message.text
      }
    }
  end

  let(:welcome_message_payload) do
    {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: contributor.whats_app_phone_number.split('+').last,
      type: 'template',
      template: {
        language: {
          policy: 'deterministic',
          code: 'de'
        },
        name: "welcome_message_#{organization.project_name.parameterize.underscore}"
      }
    }
  end

  describe '::send!' do
    subject { -> { described_class.send!(message) } }
    before { message } # we don't count the extra ::send here

    context '`whats_app_phone_number` blank' do
      it { should_not enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) }
    end

    context 'given a WhatsApp contributor' do
      let(:contributor) { create(:contributor, :whats_app_contributor, organization: organization) }

      describe 'contributor has not sent a message within 24 hours' do
        it 'enqueues the Text job with WhatsApp template' do
          expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with do |params|
                                       expect(params[:payload]).to include(new_request_payload)
                                     end)
        end
      end

      describe 'contributor has responded to a template' do
        before { contributor.update(whats_app_message_template_responded_at: Time.current) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with do |params|
            expect(params[:payload]).to eq(text_payload)
          end)
        end
      end

      describe 'contributor has sent a reply within 24 hours' do
        before { create(:message, sender: contributor) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with do |params|
            expect(params[:payload]).to eq(text_payload)
          end)
        end
      end

      describe 'message with files' do
        before { create(:file, message: message) }

        context 'contributor has not sent a message within 24 hours' do
          it 'enqueues the Text job with WhatsApp template' do
            expect do
              subject.call
            end.to(have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with do |params|
                     expect(params[:payload]).to include(new_request_payload)
                   end)
          end
        end

        context 'contributor has sent a reply within 24 hours' do
          before { create(:message, sender: contributor) }

          it 'enqueues a File job with file, contributor, text' do
            expect do
              subject.call
            end.to(have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::UploadFileJob).on_queue('default').with do |params|
                     expect(params[:message_id]).to eq(message.id)
                   end)
          end
        end
      end
    end
  end

  describe '#send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor, organization) } }

    it { is_expected.not_to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) }

    context 'contributor has a phone number' do
      let(:contributor) { create(:contributor, :whats_app_contributor, organization: organization) }

      context 'and no replies sent(new contributor)' do
        it {
          is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ organization_id: organization.id,
                                                                                             payload: welcome_message_payload })
        }
      end

      context 'with replies sent within 24 hours' do
        let(:onboarding_success_heading) { 'Thanks for onboarding' }
        let(:onboarding_success_text) { 'We will start sending messages soon.' }

        before do
          create(:message, sender: contributor)
          organization.update!(onboarding_success_heading: onboarding_success_heading, onboarding_success_text: onboarding_success_text)
          text_payload[:text][:body] = ["*#{onboarding_success_heading}*", onboarding_success_text].join("\n\n")
        end

        it {
          is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ organization_id: organization.id,
                                                                                             payload: text_payload })
        }
      end
    end
  end

  describe '#send_unsupported_content_message!' do
    subject { -> { described_class.send_unsupported_content_message!(contributor, organization) } }

    it { is_expected.not_to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) }

    context 'contributor has a phone number' do
      let(:contributor) { create(:contributor, :whats_app_contributor, organization: organization) }
      let(:contact_person) { create(:user) }
      let(:organization) { create(:organization, contact_person: contact_person) }

      before do
        text_payload[:text][:body] = I18n.t('adapter.whats_app.unsupported_content_template',
                                            first_name: contributor.first_name,
                                            contact_person: contributor.organization.contact_person.name)
      end

      it {
        is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ organization_id: organization.id,
                                                                                           payload: text_payload })
      }
    end
  end

  describe '#send_more_info_message!' do
    subject { -> { described_class.send_more_info_message!(contributor, organization) } }

    it { is_expected.not_to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) }

    context 'contributor has a phone number' do
      let(:contributor) do
        create(
          :contributor,
          whats_app_phone_number: '+491511234567',
          email: nil
        )
      end

      before do
        text_payload[:text][:body] =
          [organization.whats_app_profile_about, "_#{I18n.t('adapter.shared.unsubscribe.instructions')}_"].join("\n\n")
      end

      it {
        is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ organization_id: organization.id,
                                                                                           payload: text_payload })
      }
    end
  end

  describe '#send_unsubsribed_successfully_message!' do
    subject { -> { described_class.send_unsubsribed_successfully_message!(contributor, organization) } }

    it { is_expected.not_to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) }

    context 'contributor has a phone number' do
      let(:contributor) { create(:contributor, :whats_app_contributor, organization: organization) }

      before do
        text_payload[:text][:body] = [I18n.t('adapter.shared.unsubscribe.successful'),
                                      "_#{I18n.t('adapter.shared.resubscribe.instructions')}_"].join("\n\n")
      end

      it {
        is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ organization_id: organization.id,
                                                                                           payload: text_payload })
      }
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
