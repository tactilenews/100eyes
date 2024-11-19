# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::BroadcastMessagesJob do
  describe '#perform_later(request_id:)' do
    subject { -> { described_class.new.perform(request_id: request.id) } }

    let(:request) do
      create(:request, broadcasted_at: nil, organization: create(:organization, three_sixty_dialog_client_api_key: 'valid_client_api_key'))
    end
    let(:text_payload) do
      {
        messaging_product: 'whatsapp',
        recipient_type: 'individual',
        type: 'text',
        text: {
          body: message.text
        }
      }
    end

    describe 'given contributors from multiple organizations' do
      before do
        create(:contributor, :whats_app_contributor, id: 1, organization: request.organization)
        create(:contributor, :whats_app_contributor, id: 2, organization: request.organization)
        create(:contributor, :whats_app_contributor, id: 3)
      end

      it "schedules jobs to send out message to an organization's contributors" do
        subject.call
        expect(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).to have_been_enqueued.exactly(2).times
        request.organization.contributors.each do |contributor|
          expect(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).to have_been_enqueued.with(
            organization_id: request.organization,
            payload: text_payload.merge({ to: contributor.whats_app_phone_number.split('+').last })
          )
        end
      end

      it 'only creates a message for contributors of the organization' do
        expect { subject.call }.to change(Message, :count).from(0).to(2)
                                                          .and (change { Message.pluck(:recipient_id).sort }).from([]).to([1, 2])
      end

      it 'assigns the user of the request as the sender of the message' do
        expect { subject.call }.to (change { Message.pluck(:sender_id) }).from([]).to([request.user.id, request.user.id])
      end

      describe 'given a request with files attached', vcr: { cassette_name: :three_sixty_dialog_upload_file_service } do
        before do
          request.update!(files: [fixture_file_upload('profile_picture.jpg')])
          allow(ENV).to receive(:fetch).with('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT',
                                             'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693').and_return('https://waba-v2.360dialog.io')
        end

        it 'attaches the files to the messages' do
          expect { subject.call }.to (change { Message::File.count }).from(0).to(2)
          Message.find_each do |message|
            message.files.each do |file|
              expect(file.attachment).to be_attached
            end
          end
        end

        it "updates the request's whats_app_external_file_ids" do
          expect { subject.call }.to (change { request.reload.whats_app_external_file_ids }).from([]).to(['545466424653131'])
        end
      end

      describe 'given a request with a tag_list' do
        before do
          request.update!(tag_list: ['programmer'])
          request.organization.contributors.find(1).update!(tag_list: ['programmer'])
        end

        it 'only sends to contributors tagged with the tag' do
          expect { subject.call }.to change(Message, :count).from(0).to(1)
                                                            .and (change { Message.pluck(:recipient_id) }).from([]).to([1])
        end
      end

      describe 'given non-active contributors' do
        before do
          request.organization.contributors.find(1).update!(deactivated_at: 1.hour.ago)
          create(:contributor, :whats_app_contributor, unsubscribed_at: 1.minute.ago)
        end

        it 'only sends to active contributors' do
          expect { subject.call }.to change(Message, :count).from(0).to(1)
                                                            .and (change { Message.pluck(:recipient_id) }).from([]).to([2])
        end
      end

      describe 'given contributors of other messengers' do
        before do
          create(:contributor, :threema_contributor, :skip_validations, organization: request.organization)
          create(:contributor, :telegram_contributor, organization: request.organization)
          create(:contributor, :signal_contributor, organization: request.organization)
          create(:contributor, organization: request.organization)
        end

        it 'only creates a message for contributors of the organization' do
          expect { subject.call }.to change(Message, :count).from(0).to(2)
                                                            .and (change { Message.pluck(:recipient_id).sort }).from([]).to([1, 2])
        end
      end
    end
  end
end
