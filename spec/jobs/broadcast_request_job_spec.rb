# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastRequestJob do
  describe '#perform_later(request_id)' do
    subject { -> { described_class.new.perform(request.id) } }

    let!(:contributor) { create(:contributor) }
    let(:request) do
      create(:request, broadcasted_at: nil, organization: create(:organization, three_sixty_dialog_client_api_key: 'valid_client_api_key'))
    end

    context 'given the request has been deleted' do
      before { request.destroy }

      it 'raises an error to indicate something should be looked into' do
        expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'does not create a Message instance' do
      rescue ActiveRecord::RecordNotFound
        expect { subject.call }.not_to change(Message, :count)
      end
    end

    context 'given a request has been broadcast' do
      before { request.update(broadcasted_at: 5.minutes.ago) }

      it 'does not create a Message instance' do
        expect { subject.call }.not_to change(Message, :count)
      end

      it 'does not update the broadcasted_at attr' do
        expect { subject.call }.not_to(change { request.reload.broadcasted_at })
      end
    end

    context 'given a request has been rescheduled for the future' do
      before { request.update(schedule_send_for: 1.day.from_now) }

      it 'does not create a Message instance' do
        expect { subject.call }.not_to change(Message, :count)
      end

      it 'does not update the broadcasted_at attr' do
        expect { subject.call }.not_to(change { request.reload.broadcasted_at })
      end
    end

    context 'given a request that is to be sent out now' do
      describe 'given contributors from multiple organizations' do
        before(:each) do
          create(:contributor, id: 1, email: 'somebody@example.org', organization: request.organization)
          create(:contributor, id: 2, email: nil, telegram_id: 22, organization: request.organization)
          create(:contributor, id: 3)
        end

        it "schedules jobs to send out message with contributor's channel" do
          subject.call

          expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with(
            'PostmarkAdapter::Outbound',
            'message_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { message: request.messages.where(recipient_id: 1).first, organization: request.organization },
              args: []
            }
          )
          expect(TelegramAdapter::Outbound::Text).to have_been_enqueued.with({ organization_id: request.organization.id,
                                                                               contributor_id: 2,
                                                                               text: request.text,
                                                                               message: request.messages.where(recipient_id: 2).first })
        end

        it 'only sends to contributors of the organization' do
          expect { subject.call }.to change(Message, :count).from(0).to(2)
                                                            .and (change { Message.pluck(:recipient_id).sort }).from([]).to([1, 2])
        end

        it 'assigns the user of the request as the sender of the message' do
          expect { subject.call }.to (change { Message.pluck(:sender_id) }).from([]).to([request.user.id, request.user.id])
        end

        it 'marks the messages as broadcasted' do
          expect { subject.call }.to (change { Message.pluck(:broadcasted) }).from([]).to([true, true])
        end

        context 'and has files attached' do
          before do
            request.files.attach(
              io: Rails.root.join('example-image.png').open,
              filename: 'example-image.png'
            )
          end

          it 'attaches the files to the messages' do
            expect { subject.call }.to (change { Message::File.count }).from(0).to(2)
            Message.find_each do |message|
              message.files.each do |file|
                expect(file.attachment).to be_attached
              end
            end
          end
        end
      end

      describe 'given a request with a tag_list' do
        let(:request) do
          create(:request,
                 title: 'Hitchhiker’s Guide',
                 text: 'What is the answer to life, the universe, and everything?',
                 tag_list: 'programmer',
                 broadcasted_at: nil)
        end

        before do
          create(:contributor, id: 4, organization: request.organization, tag_list: ['programmer'])
          create(:contributor, id: 5, organization: request.organization, tag_list: ['something_else'])
          create(:contributor, id: 6, organization: request.organization)
        end

        it 'only sends to contributors tagged with the tag' do
          expect { subject.call }.to change(Message, :count).from(0).to(1)
                                                            .and (change { Message.pluck(:recipient_id) }).from([]).to([4])
        end
      end

      describe 'given contributors who are deactivated' do
        before(:each) do
          create(:contributor, :inactive, id: 7, organization: request.organization)
          create(:contributor, id: 8, organization: request.organization)
          create(:contributor, :inactive, id: 9, telegram_id: 24, organization: request.organization)
        end

        it 'only sends to active contributors' do
          expect { subject.call }.to change(Message, :count).from(0).to(1)
                                                            .and (change { Message.pluck(:recipient_id) }).from([]).to([8])
        end
      end

      describe 'given a request with files attached', vcr: { cassette_name: :three_sixty_dialog_upload_file_service } do
        before do
          request.update!(files: [fixture_file_upload('profile_picture.jpg')])
        end

        context 'no WhatsApp contributors as recipients' do
          it "does not update the request's external_file_ids since WhatsApp won't be used to send files" do
            expect { subject.call }.not_to(change { request.reload.external_file_ids })
          end
        end

        context 'with WhatsApp contributors as recipients' do
          before { create(:contributor, :whats_app_contributor, organization: request.organization) }

          it "updates the request's external_file_ids" do
            expect { subject.call }.to (change { request.reload.external_file_ids }).from([]).to(['545466424653131'])
          end
        end
      end
    end
  end
end
