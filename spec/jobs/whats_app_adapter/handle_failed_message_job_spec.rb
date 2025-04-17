# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::HandleFailedMessageJob do
  describe '#perform_later(contributor_id:, external_message_id:)' do
    subject { -> { described_class.new.perform(contributor_id: contributor.id, external_message_id: external_message_id) } }

    let!(:contributor) { create(:contributor, :whats_app_contributor) }
    let(:external_message_id) { nil }
    let(:message) { create(:message) }

    describe 'unknown message' do
      it 'is expected not to raise an error' do
        expect { subject.call }.not_to raise_error
      end

      it 'does not schedule a job to mark contributor as inactive' do
        expect { subject.call }.not_to have_enqueued_job(MarkInactiveContributorInactiveJob)
      end

      it 'increments the whats_app_message_failed_count by 1' do
        expect { subject.call }.to change { contributor.reload.whats_app_message_failed_count }.from(0).to(1)
      end

      context 'three failed messages' do
        before { contributor.update(whats_app_message_failed_count: 2) }

        it 'schedules a job to mark contributor inactive' do
          expect { subject.call }.to have_enqueued_job(MarkInactiveContributorInactiveJob).with(
            contributor_id: contributor.id
          )
        end
      end
    end

    describe 'message with external_id found' do
      let(:external_message_id) { 'wamid.<some_valid_external_message_id>' }

      before { message.update(external_id: external_message_id) }

      context 'given the message was not marked as delivered' do
        it 'increments the whats_app_message_failed_count by 1' do
          expect { subject.call }.to change { contributor.reload.whats_app_message_failed_count }.from(0).to(1)
        end

        context 'three failed messages' do
          before { contributor.update(whats_app_message_failed_count: 2) }

          it 'schedules a job to mark contributor inactive' do
            expect { subject.call }.to have_enqueued_job(MarkInactiveContributorInactiveJob).with(
              contributor_id: contributor.id
            )
          end
        end
      end

      context 'given the message has been marked as delivered' do
        before do
          message.update(delivered_at: 3.hours.ago)
          contributor.update(whats_app_message_failed_count: 2)
        end

        it 'does not increment the whats_app_message_failed_count since it is a false positive' do
          expect { subject.call }.not_to(change { contributor.reload.whats_app_message_failed_count })
        end

        it 'does not schedule a job to mark contributor as inactive' do
          expect { subject.call }.not_to have_enqueued_job(MarkInactiveContributorInactiveJob)
        end
      end
    end

    describe 'whats_app message template with external_id found' do
      let(:external_message_id) { 'wamid.<some_valid_external_message_id>' }
      let(:whats_app_message_template) { create(:message_whats_app_template, external_id: external_message_id, message: message) }

      context 'given the whats_app message template was not marked as delivered' do
        it 'increments the whats_app_message_failed_count by 1' do
          expect { subject.call }.to change { contributor.reload.whats_app_message_failed_count }.from(0).to(1)
        end

        context 'three failed messages' do
          before { contributor.update(whats_app_message_failed_count: 2) }

          it 'schedules a job to mark contributor inactive' do
            expect { subject.call }.to have_enqueued_job(MarkInactiveContributorInactiveJob).with(
              contributor_id: contributor.id
            )
          end
        end
      end

      context 'given the whats_app message template has been marked as delivered' do
        before do
          whats_app_message_template.update(delivered_at: 3.hours.ago)
          contributor.update(whats_app_message_failed_count: 2)
        end

        it 'does not increment the whats_app_message_failed_count since it is a false positive' do
          expect { subject.call }.not_to(change { contributor.reload.whats_app_message_failed_count })
        end

        it 'does not schedule a job to mark contributor as inactive' do
          expect { subject.call }.not_to have_enqueued_job(MarkInactiveContributorInactiveJob)
        end
      end
    end
  end
end
