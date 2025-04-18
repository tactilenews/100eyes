# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialogOutbound do
  let(:adapter) { described_class.new }
  let(:organization) do
    create(:organization,
           project_name: 'Great project',
           whats_app_more_info_message: "We're cool, but if you want to unsubscribe, write 'unsubscribe'")
  end
  let!(:message) do
    create(:message, :outbound, text: '360dialog is great!', broadcasted: true, recipient: contributor,
                                request: create(:request, organization: organization))
  end
  let(:contributor) { create(:contributor, organization: organization) }

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
          expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with(
            contributor_id: contributor.id,
            type: :request_template,
            message_id: message.id
          )
        end
      end

      describe 'contributor has responded to a template' do
        before { contributor.update(whats_app_message_template_responded_at: Time.current) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with(
            contributor_id: contributor.id,
            type: :text,
            message_id: message.id
          )
        end
      end

      describe 'contributor has sent a reply within 24 hours' do
        before { create(:message, sender: contributor) }

        it 'enqueues the Text job with the request text' do
          expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with(
            contributor_id: contributor.id,
            type: :text,
            message_id: message.id
          )
        end
      end

      describe 'message with files' do
        before { create(:file, message: message) }

        context 'contributor has not sent a message within 24 hours' do
          it 'enqueues the Text job with WhatsApp template' do
            expect do
              subject.call
            end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with(
              contributor_id: contributor.id,
              type: :request_template,
              message_id: message.id
            )
          end
        end

        context 'contributor has sent a reply within 24 hours' do
          before do
            create(:message, sender: contributor)
          end

          it 'enqueues a File job with file, contributor, text' do
            expect do
              subject.call
            end.to(have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::File).on_queue('default').with do |params|
                     expect(params[:message_id]).to eq(message.id)
                   end)
          end
        end
      end
    end
  end

  describe '#send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor) } }

    it { is_expected.not_to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) }

    context 'contributor has a phone number' do
      let(:contributor) { create(:contributor, :whats_app_contributor, organization: organization) }

      context 'and no replies sent(new contributor)' do
        it {
          is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ contributor_id: contributor.id,
                                                                                             type: :welcome_message_template })
        }
      end

      context 'with replies sent within 24 hours' do
        let(:onboarding_success_heading) { 'Thanks for onboarding' }
        let(:onboarding_success_text) { 'We will start sending messages soon.' }

        before do
          create(:message, sender: contributor)
          organization.update!(onboarding_success_heading: onboarding_success_heading, onboarding_success_text: onboarding_success_text)
        end

        it {
          is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ contributor_id: contributor.id,
                                                                                             type: :text,
                                                                                             text: ["*#{onboarding_success_heading}*",
                                                                                                    onboarding_success_text].join("\n\n") })
        }
      end
    end
  end

  describe '#send_unsupported_content_message!' do
    subject { -> { described_class.send_unsupported_content_message!(contributor) } }

    it { is_expected.not_to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) }

    context 'contributor has a phone number' do
      let(:contributor) { create(:contributor, :whats_app_contributor, organization: organization) }
      let(:contact_person) { create(:user) }
      let(:organization) { create(:organization, contact_person: contact_person) }
      let(:unsupported_content_text) do
        I18n.t('adapter.whats_app.unsupported_content_template',
               first_name: contributor.first_name,
               contact_person: contributor.organization.contact_person.name)
      end

      it {
        is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ contributor_id: contributor.id,
                                                                                           type: :text,
                                                                                           text: unsupported_content_text })
      }
    end
  end

  describe '#send_more_info_message!' do
    subject { -> { described_class.send_more_info_message!(contributor) } }

    it { is_expected.not_to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) }

    context 'contributor has a phone number' do
      let(:contributor) do
        create(
          :contributor,
          whats_app_phone_number: '+491511234567',
          email: nil,
          organization: organization
        )
      end

      before do
        organization.update!(whats_app_more_info_message: 'Here is more info!')
      end

      it {
        is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ contributor_id: contributor.id,
                                                                                           type: :text,
                                                                                           text: 'Here is more info!' })
      }
    end
  end

  describe '#send_unsubscribed_successfully_message!' do
    subject { -> { described_class.send_unsubscribed_successfully_message!(contributor) } }

    it { is_expected.not_to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) }

    context 'contributor has a phone number' do
      let(:contributor) { create(:contributor, :whats_app_contributor, organization: organization) }
      let(:unsubscribed_successfully_text) do
        [I18n.t('adapter.shared.unsubscribe.successful'),
         "_#{I18n.t('adapter.shared.resubscribe.instructions')}_"].join("\n\n")
      end

      it {
        is_expected.to enqueue_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with({ contributor_id: contributor.id,
                                                                                           type: :text,
                                                                                           text: unsubscribed_successfully_text })
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
