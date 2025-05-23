# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialog::ProcessWebhookJob do
  describe '#perform_later(organization_id:, components:)' do
    subject { -> { described_class.new.perform(organization_id: organization.id, components: components) } }

    let(:organization) do
      create(:organization,
             three_sixty_dialog_client_api_key: 'valid_api_key',
             whats_app_quick_reply_button_text: { answer_request: 'Mehr Infos', more_info: 'Über uns' },
             whats_app_more_info_message: "Please do not unsubscribe. Unless you want to. Then send a 'unsubscribe'")
    end
    let(:components) do
      {
        messaging_product: 'whatsapp',
        metadata: { display_phone_number: '4915133311445', phone_number_id: 'some_valid_id' },
        contacts: [{ profile: { name: 'Matthew Rider' },
                     wa_id: '491511234567' }],
        messages: [{ from: '491511234567',
                     id: 'some_valid_id',
                     text: { body: 'Hey' },
                     timestamp: '1692118778',
                     type: 'text' }]
      }
    end

    describe 'unknown contributor' do
      before { allow(Sentry).to receive(:capture_exception) }

      it 'does not create a message' do
        expect { subject.call }.not_to change(Message, :count)
      end

      it 'raises an error' do
        expect(Sentry).to receive(:capture_exception).with(
          WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: '+491511234567')
        )

        subject.call
      end
    end

    describe 'given a contributor' do
      let(:whats_app_phone_number) { '+491511234567' }
      let(:contributor) { create(:contributor, whats_app_phone_number: whats_app_phone_number, organization: organization) }
      let(:request) { create(:request, organization: organization) }
      let!(:latest_message) { create(:message, :outbound, request: request, recipient: contributor) }

      context 'no message template sent' do
        it 'creates a message' do
          expect { subject.call }.to change(Message, :count).from(1).to(2)
        end
      end

      context 'responding to template' do
        let(:whats_app_template) { create(:message_whats_app_template, message: latest_message, external_id: 'some_external_template_id') }
        let(:text) { latest_message.text }

        before { whats_app_template }

        context 'request to receive latest message' do
          before { components[:messages].first[:context] = { id: 'some_external_template_id' } }

          it 'marks that contributor has responded to template message' do
            expect { subject.call }.to change {
              contributor.reload.whats_app_message_template_responded_at
            }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end

          describe 'with no external id' do
            let(:base_uri) { 'https://waba-v2.360dialog.io' }
            let(:external_file_id) { '545466424653131' }

            before do
              latest_message.request.update!(whats_app_external_file_ids: [external_file_id])
              allow(ENV).to receive(:fetch).with(
                'THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693'
              ).and_return(base_uri)
              stub_request(:post, "#{base_uri}/messages").to_return(status: 200, body: { messages: [id: 'some_external_id'] }.to_json)
            end

            it 'enqueues a job to send the latest received message' do
              expect do
                subject.call
              end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with(
                contributor_id: contributor.id,
                type: :text,
                message_id: latest_message.id
              )
            end

            it 'updates the message with the external id' do
              perform_enqueued_jobs do
                expect { subject.call }.to (change { latest_message.reload.external_id }).from(nil).to('some_external_id')
              end
            end

            context 'message with file, no text' do
              let(:message_file) do
                [create(:file, message: latest_message,
                               attachment: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/matt.jpeg'), 'image/jpeg'))]
              end

              before do
                latest_message.update!(text: '', files: message_file)
              end

              it 'enqueues a job to send the file' do
                expect { subject.call }.to have_enqueued_job(
                  WhatsAppAdapter::ThreeSixtyDialogOutbound::File
                ).with({ message_id: latest_message.id })
              end

              it 'updates the message with the external id' do
                perform_enqueued_jobs do
                  expect { subject.call }.to (change { latest_message.reload.external_id }).from(nil).to('some_external_id')
                end
              end

              context 'message with file and text' do
                before do
                  latest_message.update!(text: 'Some text')
                end

                it 'enqueues a job to upload the file' do
                  expect do
                    subject.call
                  end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::File).on_queue('default').with(
                    message_id: latest_message.id
                  )
                end

                context 'given the text is greater than 1024' do
                  before { latest_message.update!(text: Faker::Lorem.characters(number: 1025)) }

                  it 'enqueues a job to send out the text' do
                    perform_enqueued_jobs(except: WhatsAppAdapter::ThreeSixtyDialogOutbound::Text) do
                      expect do
                        subject.call
                      end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with(
                        contributor_id: contributor.id,
                        type: :text,
                        message_id: latest_message.id
                      )
                    end
                  end
                end
              end
            end
          end

          describe 'with an external id' do
            let(:previous_message) do
              create(:message, :outbound, request: request, recipient: contributor, created_at: 2.days.ago)
            end
            let(:whats_app_template) { create(:message_whats_app_template, message: previous_message, external_id: 'some_external_id') }
            let(:text) { previous_message.text }

            before do
              whats_app_template
              components[:messages].first[:context] = { id: 'some_external_id' }
            end

            it 'sends out the message with that external id' do
              expect do
                subject.call
              end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with(
                contributor_id: contributor.id,
                type: :text,
                message_id: previous_message.id
              )
            end
          end
        end
      end

      context 'request for more info' do
        before do
          components[:messages].first.delete(:text)
          components[:messages].first[:button] = { text: 'Über uns' }
        end
        let(:text) { organization.whats_app_more_info_message }

        it 'marks that contributor has responded to template message' do
          expect { subject.call }.to change {
                                       contributor.reload.whats_app_message_template_responded_at
                                     }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
        end

        it 'enqueues a job to send more info message' do
          expect do
            subject.call
          end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).on_queue('default').with(
            contributor_id: contributor.id,
            type: :text,
            text: text
          )
        end

        context 'does not enqueue a job' do
          it 'to send the latest received message' do
            expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
              contributor_id: contributor.id,
              type: :text,
              message_id: latest_message.id
            )
          end
        end
      end

      context 'request to unsubscribe' do
        before { components[:messages].first[:text][:body] = 'Abbestellen' }

        it 'is expected to enqueue a job to unsubscribe' do
          expect { subject.call }.to have_enqueued_job(UnsubscribeContributorJob).with(contributor.id,
                                                                                       WhatsAppAdapter::ThreeSixtyDialogOutbound)
        end
      end

      context 'request to re-subscribe' do
        before do
          contributor.update(unsubscribed_at: Time.current)
          components[:messages].first[:text][:body] = 'Bestellen'
        end

        it 'is expected to enqueue a job to unsubscribe' do
          expect { subject.call }.to have_enqueued_job(ResubscribeContributorJob).with(contributor.id,
                                                                                       WhatsAppAdapter::ThreeSixtyDialogOutbound)
        end
      end

      context 'files' do
        let(:message) { components[:messages].first }
        let(:file_id) { 'some_valid_id' }
        let(:path) { '/whatsapp_business/attachments/' }
        let(:query) { "?mid=#{file_id}&ext=1727097743&hash=ATu6wfuxkGsA6z-jlTHimX3hb8TTrWgHeDsaLZ-Qs7ab6g" }
        let(:fetch_file_url) { "https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693/#{file_id}" }
        let(:fetch_streamable_file) do
          "https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693#{path}#{query}"
        end

        before { message.delete(:text) }

        context 'supported content' do
          before do
            allow(ENV).to receive(:fetch).with('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT',
                                               'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693').and_return('https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
            stub_request(:get, fetch_file_url).to_return(status: 200,
                                                         body: { url: "https://someurl.com#{path}#{query}" }.to_json)
            stub_request(:get, fetch_streamable_file).to_return(status: 200, body: 'some_streamable_file')
          end

          context 'image' do
            let(:image) do
              {
                id: 'some_valid_id',
                mime_type: 'image/jpeg',
                sha256: 'sha256_hash'
              }
            end
            before do
              message[:type] = 'image'
              message[:image] = image
            end

            it 'creates a new Message::File' do
              expect { subject.call }.to change(Message::File, :count).from(0).to(1)
            end

            it 'creates a new Message' do
              expect { subject.call }.to change(Message, :count).from(1).to(2)
            end

            it 'attaches the file to the message with its mime_type' do
              subject.call

              latest_message = Message.where(sender: contributor).first
              expect(latest_message.files.first).to eq(Message::File.first)
              expect(latest_message.files.first.attachment.content_type).to eq(message[:image][:mime_type])
            end
          end

          context 'voice' do
            let(:voice) do
              {
                id: 'some_valid_id',
                mime_type: 'audio/ogg; codecs=opus',
                sha256: 'sha256_hash'
              }
            end
            before do
              message[:type] = 'voice'
              message[:voice] = voice
            end

            it 'creates a new Message::File' do
              expect { subject.call }.to change(Message::File, :count).from(0).to(1)
            end

            it 'creates a new Message' do
              expect { subject.call }.to change(Message, :count).from(1).to(2)
            end

            it 'attaches the file to the message' do
              subject.call

              expect(Message.first.files.first).to eq(Message::File.first)
            end
          end

          context 'video' do
            let(:video) do
              {
                id: 'some_valid_id',
                mime_type: 'video/mp4',
                sha256: 'sha256_hash'
              }
            end
            before do
              message[:type] = 'video'
              message[:video] = video
            end

            it 'creates a new Message::File' do
              expect { subject.call }.to change(Message::File, :count).from(0).to(1)
            end

            it 'creates a new Message' do
              expect { subject.call }.to change(Message, :count).from(1).to(2)
            end

            it 'attaches the file to the message with its mime_type' do
              subject.call

              latest_message = Message.where(sender: contributor).first
              expect(latest_message.files.first).to eq(Message::File.first)
              expect(latest_message.files.first.attachment.content_type).to eq(message[:video][:mime_type])
            end
          end

          context 'audio' do
            let(:audio) do
              {
                id: 'some_valid_id',
                mime_type: 'audio/ogg',
                sha256: 'sha256_hash'
              }
            end
            before do
              message[:type] = 'audio'
              message[:audio] = audio
            end

            it 'creates a new Message::File' do
              expect { subject.call }.to change(Message::File, :count).from(0).to(1)
            end

            it 'creates a new Message' do
              expect { subject.call }.to change(Message, :count).from(1).to(2)
            end

            it 'attaches the file to the message with its mime_type' do
              subject.call

              latest_message = Message.where(sender: contributor).first
              expect(latest_message.files.first).to eq(Message::File.first)
              expect(latest_message.files.first.attachment.content_type).to eq(message[:audio][:mime_type])
            end
          end

          context 'document' do
            context 'image' do
              let(:document) do
                {
                  filename: 'animated-cat-image-0056.gif',
                  id: 'some_valid_id',
                  mime_type: 'image/gif',
                  sha256: 'sha256_hash'
                }
              end

              before do
                message[:type] = 'document'
                message[:document] = document
              end

              it 'attaches the file to the message with its mime_type' do
                subject.call

                latest_message = Message.where(sender: contributor).first
                expect(latest_message.files.first.attachment).to be_attached
                expect(latest_message.files.first.attachment.content_type).to eq(message[:document][:mime_type])
              end
            end

            context 'audio' do
              let(:document) do
                {
                  filename: 'AUD-12345.opus',
                  id: 'some_valid_id',
                  mime_type: 'audio/ogg',
                  sha256: 'sha256_hash'
                }
              end

              before do
                message[:type] = 'document'
                message[:document] = document
              end

              it 'attaches the file to the message with its mime_type' do
                subject.call

                latest_message = Message.where(sender: contributor).first
                expect(latest_message.files.first.attachment).to be_attached
                expect(latest_message.files.first.attachment.content_type).to eq(message[:document][:mime_type])
              end
            end

            context 'video' do
              let(:document) do
                {
                  filename: 'VID_12345.mp4',
                  id: 'some_valid_id',
                  mime_type: 'video/mp4',
                  sha256: 'sha256_hash'
                }
              end

              before do
                message[:type] = 'document'
                message[:document] = document
              end

              it 'attaches the file to the message with its mime_type' do
                subject.call

                latest_message = Message.where(sender: contributor).first
                expect(latest_message.files.first.attachment).to be_attached
                expect(latest_message.files.first.attachment.content_type).to eq(message[:document][:mime_type])
              end
            end
          end
        end

        context 'unsupported content' do
          before { organization.update!(contact_person: contact_person) }
          let(:contact_person) { create(:user) }
          let(:unsupported_content_text) do
            I18n.t('adapter.whats_app.unsupported_content_template', first_name: contributor.first_name,
                                                                     contact_person: contributor.organization.contact_person.name)
          end

          context 'document' do
            let(:document) do
              {
                filename: 'Comprovante.pdf',
                id: 'some_valid_id',
                mime_type: 'application/pdf',
                sha256: 'sha256_hash'
              }
            end
            before do
              message[:type] = 'document'
              message[:document] = document
            end

            it 'sends a message to contributor to let them know the message type is not supported' do
              expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
                contributor_id: contributor.id,
                type: :text,
                text: unsupported_content_text
              )
            end
          end

          context 'location' do
            let(:location) do
              {
                latitude: '22.9871',
                longitude: '43.2048'
              }
            end
            before do
              message[:type] = 'location'
              message[:location] = location
            end

            it 'sends a message to contributor to let them know the message type is not supported' do
              expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
                contributor_id: contributor.id,
                type: :text,
                text: unsupported_content_text
              )
            end
          end

          context 'contacts' do
            let(:contacts) do
              {
                contacts: [
                  { addresses: [],
                    emails: [],
                    ims: [],
                    name: {
                      first_name: '360dialog',
                      formatted_name: '360dialog Sandbox',
                      last_name: 'Sandbox'
                    },
                    org: {},
                    phones: [
                      { phone: '+49 30 609859535',
                        type: 'Mobile',
                        wa_id: '4930609859535' }
                    ], urls: [] }
                ],
                from: '4915143416265',
                id: 'some_valid_id',
                timestamp: '1692123428',
                type: 'contacts'
              }
            end
            before do
              message[:type] = 'contacts'
              message[:contacts] = contacts
            end

            it 'sends a message to contributor to let them know the message type is not supported' do
              expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
                contributor_id: contributor.id,
                type: :text,
                text: unsupported_content_text
              )
            end
          end

          context 'stickers' do
            let(:sticker) do
              {
                mime_type: 'image/webp',
                sha256: 'sha256_hash',
                id: 'some_valid_id',
                animated: false
              }
            end

            before do
              message[:type] = 'sticker'
              message[:sticker] = sticker
            end

            it 'sends a message to contributor to let them know the message type is not supported' do
              expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
                contributor_id: contributor.id,
                type: :text,
                text: unsupported_content_text
              )
            end
          end
        end
      end

      context 'reactions' do
        before do
          components[:messages] = [{
            from: '491511234567',
            id: 'some_valid_id',
            timestamp: '1692118778',
            type: 'reaction',
            reaction: {
              message_id: 'wamid.HBgNNDkxNTE0MzQxNjI2NRUCABEYEjAwNEM1QzE4M0IxNUFDRTAxQgA=',
              emoji: '❤'
            }
          }]
        end

        it 'saves the message' do
          expect { subject.call }.to change(Message, :count).from(1).to(2)
        end

        it 'saves the emoji as text of the message' do
          subject.call
          message = contributor.replies.first
          expect(message.text).to eq('❤')
        end
      end
    end
  end
end
