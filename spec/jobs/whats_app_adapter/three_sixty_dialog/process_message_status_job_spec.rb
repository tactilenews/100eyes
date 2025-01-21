# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialog::ProcessMessageStatusJob do
  describe '#perform_later(organization_id:, status:)' do
    subject { -> { described_class.new.perform(organization_id: organization.id, delivery_receipt: delivery_receipt) } }

    let(:organization) do
      create(:organization,
             three_sixty_dialog_client_api_key: 'valid_api_key')
    end

    let(:base_delivery_receipt) do
      {
        'id' => 'valid_message_id',
        'status' => '',
        'timestamp' => '1732132030',
        'recipient_id' => '49123456789',
        'conversation' => {
          'id' => 'valid_conversation_id', 'origin' => {
            'type' => 'marketing'
          }
        },
        'pricing' => {
          'billable' => 'true', 'pricing_model' => 'CBP', 'category' => 'marketing'
        }
      }.deep_transform_keys(&:to_sym)
    end

    describe 'unknown contributor' do
      let(:delivery_receipt) { base_delivery_receipt }
      before { allow(Sentry).to receive(:capture_exception) }

      it 'raises an error' do
        expect(Sentry).to receive(:capture_exception).with(
          WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: '+49123456789')
        )

        subject.call
      end
    end

    describe 'given a contributor' do
      let(:whats_app_phone_number) { '+49123456789' }
      let!(:contributor) { create(:contributor, whats_app_phone_number: whats_app_phone_number, organization: organization) }
      let(:delivery_receipt) { base_delivery_receipt }

      it 'is expected not to raise an error' do
        expect { subject.call }.not_to raise_error
      end

      context 'no message found by external id' do
        it 'is expected not to raise an error' do
          expect { subject.call }.not_to raise_error
        end
      end

      context 'given a WhatsApp template with external id' do
        let!(:whats_app_template) { create(:message_whats_app_template, message: message, external_id: 'valid_message_id') }
        let(:message) { create(:message, recipient: contributor) }
        let(:datetime_from_timestamp) { Time.zone.at('1732132030'.to_i).to_datetime }

        context 'sent status' do
          let(:delivery_receipt) { base_delivery_receipt.merge(status: 'sent') }

          it 'updates the sent at attribute of the record' do
            expect { subject.call }.to (change { whats_app_template.reload.sent_at }).from(nil).to(datetime_from_timestamp)
          end
        end

        context 'delivered status' do
          let(:delivery_receipt) { base_delivery_receipt.merge(status: 'delivered') }

          it 'updates the received at attribute of the record' do
            expect { subject.call }.to (change { whats_app_template.reload.delivered_at }).from(nil).to(datetime_from_timestamp)
          end
        end

        context 'read status' do
          let(:delivery_receipt) { base_delivery_receipt.merge(status: 'read') }

          it 'updates the read at attribute of the record' do
            expect { subject.call }.to (change { whats_app_template.reload.read_at }).from(nil).to(datetime_from_timestamp)
          end

          context 'given delivered_at is blank' do
            it "also updates the `delivered_at`, because if you've read the message, you must have received it first" do
              expect { subject.call }.to (change { whats_app_template.reload.delivered_at }).from(nil).to(datetime_from_timestamp)
            end
          end
        end
      end

      context 'given a message with external id' do
        let(:message) { create(:message, external_id: 'valid_message_id', recipient: contributor) }
        let(:datetime_from_timestamp) { Time.zone.at('1732132030'.to_i).to_datetime }

        context 'sent status' do
          let(:delivery_receipt) { base_delivery_receipt.merge(status: 'sent') }

          it 'updates the sent at attribute of the record' do
            expect { subject.call }.to (change { message.reload.sent_at }).from(nil).to(datetime_from_timestamp)
          end
        end

        context 'delivered status' do
          let(:delivery_receipt) { base_delivery_receipt.merge(status: 'delivered') }

          it 'updates the delivered at attribute of the record' do
            expect { subject.call }.to (change { message.reload.delivered_at }).from(nil).to(datetime_from_timestamp)
          end
        end

        context 'read status' do
          let(:delivery_receipt) { base_delivery_receipt.merge(status: 'read') }

          it 'updates the read at attribute of the record' do
            expect { subject.call }.to (change { message.reload.read_at }).from(nil).to(datetime_from_timestamp)
          end

          context 'given delivered_at is blank' do
            it "also updates the `delivered_at`, because if you've read the message, you must have received it first" do
              expect { subject.call }.to (change { message.reload.delivered_at }).from(nil).to(datetime_from_timestamp)
            end
          end
        end

        context 'given a status other than successful delivery' do
          let(:delivery_receipt) { base_delivery_receipt.merge(status: 'undelivered') }

          it 'is expected not to raise an error' do
            expect { subject.call }.not_to raise_error
          end
        end

        context 'given the message with the external id was not sent to the contributor' do
          let(:delivery_receipt) { base_delivery_receipt.merge(status: 'sent') }
          let(:message) { create(:message, external_id: 'valid_message_id', recipient: create(:contributor)) }

          it 'is expected not to update the message' do
            expect { subject.call }.not_to(change { message.reload.sent_at })
          end
        end
      end
    end
  end
end
