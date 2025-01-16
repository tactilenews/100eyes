# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialog::HandleEphemeralDataJob do
  describe '#perform_later(type:, contributor_id:, message_id: nil)' do
    subject { -> { described_class.new.perform(type: type, contributor_id: contributor_id, message_id: message_id) } }

    let(:type) { :request_for_more_info }
    let(:contributor) { create(:contributor, whats_app_phone_number: '+4912345678') }
    let(:contributor_id) { contributor.id }
    let(:message_id) { nil }

    describe 'given a request for more info type' do
      before do
        contributor.organization.update!(whats_app_more_info_message: 'More info abut us.')
      end

      it 'updates the timestamp to mark they sent us a message' do
        expect { subject.call }.to change {
                                     contributor.reload.whats_app_message_template_responded_at
                                   }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it "schedules a job to send out the organization's more info message" do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          contributor_id: contributor.id,
          type: :text,
          text: 'More info abut us.'
        )
      end
    end

    describe 'given an unsubscribe type' do
      let(:type) { :unsubscribe }

      it 'schedules a job to unsubscribe the contributor' do
        expect { subject.call }.to have_enqueued_job(UnsubscribeContributorJob).with(
          contributor.organization.id,
          contributor.id,
          WhatsAppAdapter::ThreeSixtyDialogOutbound
        )
      end
    end

    describe 'given a resubscribe type' do
      let(:type) { :resubscribe }

      it 'schedules a job to resubscribe the contributor' do
        expect { subject.call }.to have_enqueued_job(ResubscribeContributorJob).with(
          contributor.organization.id,
          contributor.id,
          WhatsAppAdapter::ThreeSixtyDialogOutbound
        )
      end
    end

    describe 'given a request to receive message type' do
      let(:type) { :request_to_receive_message }
      let(:previous_message) { create(:message, :outbound, recipient: contributor) }
      let(:latest_message) { create(:message, :outbound, recipient: contributor) }

      before do
        previous_message
        latest_message
      end

      it 'updates the timestamp to mark they sent us a message' do
        expect { subject.call }.to change {
          contributor.reload.whats_app_message_template_responded_at
        }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it "sends out the contributor's latest message" do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          contributor_id: contributor.id,
          type: :text,
          message_id: latest_message.id
        )
      end

      context 'given a message id' do
        context 'when no message is found' do
          let(:message_id) { 'you_cant_find_me' }

          it 'raises an error to alert us something is wrong' do
            expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'when a message is found' do
          let(:message_id) { previous_message.id }

          it 'updates the timestamp to mark they sent us a message' do
            expect { subject.call }.to change {
              contributor.reload.whats_app_message_template_responded_at
            }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end

          it "sends out the contributor's latest message" do
            expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
              contributor_id: contributor.id,
              type: :text,
              message_id: previous_message.id
            )
          end
        end
      end
    end
  end
end
