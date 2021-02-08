# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe '/contributors', type: :request do
  let(:contributor) { create(:contributor) }
  let(:the_request) { create(:request) }
  let(:user) { create(:user) }

  describe 'GET /index' do
    it 'should be successful' do
      get contributors_url(as: user)
      expect(response).to be_successful
    end
  end

  describe 'GET /show' do
    it 'should be successful' do
      get contributor_url(contributor, as: user)
      expect(response).to be_successful
    end
  end

  describe 'GET /requests/:id' do
    it 'should be successful' do
      get contributor_request_path(id: the_request.id, contributor_id: contributor.id, as: user)
      expect(response).to be_successful
    end
  end

  describe 'GET /count' do
    let!(:teachers) { create_list(:contributor, 2, tag_list: 'teacher') }

    it 'returns count of contributors with a specific tag' do
      get count_contributors_path(tag_list: ['teacher'], as: user)
      expect(response.body).to eq({ count: 2 }.to_json)
    end
  end

  describe 'PATCH /update' do
    let(:new_attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        phone: '012345678',
        zip_code: '12345',
        city: 'Musterstadt',
        note: '11 Jahre alt',
        email: 'zora@example.org',
        tag_list: 'programmer,student'
      }
    end

    subject { -> { patch contributor_url(contributor, as: user), params: { contributor: new_attrs } } }

    it 'updates the requested contributor' do
      subject.call
      contributor.reload

      expect(contributor.first_name).to eq('Zora')
      expect(contributor.last_name).to eq('Zimmermann')
      expect(contributor.phone).to eq('012345678')
      expect(contributor.zip_code).to eq('12345')
      expect(contributor.city).to eq('Musterstadt')
      expect(contributor.note).to eq('11 Jahre alt')
      expect(contributor.email).to eq('zora@example.org')
      expect(contributor.tag_list).to eq(%w[programmer student])
    end

    context 'removing tags' do
      let(:updated_attrs) do
        { tag_list: 'ops' }
      end
      let(:contributor) { create(:contributor, tag_list: %w[dev ops]) }

      it 'is supported' do
        patch contributor_url(contributor, as: user), params: { contributor: updated_attrs }
        contributor.reload
        expect(contributor.tag_list).to eq(['ops'])
        expect(Contributor.all_tags.count).to eq(1)
      end
    end

    it 'redirects to the contributor' do
      subject.call
      expect(response).to redirect_to(contributor_url(contributor))
    end

    it 'shows success message' do
      subject.call
      expect(flash[:success]).to eq('Informationen zu Zora Zimmermann gespeichert')
    end
  end

  describe 'DELETE /destroy' do
    subject { -> { delete contributor_url(contributor, as: user) } }
    before(:each) { contributor }

    it 'destroys the requested contributor' do
      expect { subject.call }.to change(Contributor, :count).by(-1)
    end

    it 'redirects to the contributors list' do
      subject.call
      expect(response).to redirect_to(contributors_url)
    end
  end

  describe 'POST /message', telegram_bot: :rails do
    subject do
      lambda do
        post message_contributor_url(contributor, as: user), params: { message: { text: 'Forgot to ask: How are you?' } }
      end
    end

    describe 'given a contributor' do
      let(:params) { {} }
      let(:contributor) { create(:contributor, **params) }

      describe 'response' do
        before(:each) { subject.call }
        it { expect(response).to have_http_status(:bad_request) }
      end

      describe 'given an active request' do
        before(:each) { create(:message, request: the_request, recipient: contributor) }

        describe 'response' do
          before(:each) { subject.call }
          let(:newest_message) { Message.reorder(created_at: :desc).first }
          it do
            expect(response)
              .to redirect_to(
                contributor_request_path(
                  contributor_id: contributor.id,
                  id: the_request.id,
                  anchor: "chat-row-#{newest_message.id}"
                )
              )
          end
        end

        describe 'with a `telegram_id`' do
          let(:params) { { email: nil, telegram_id: 4 } }
          let(:chat_id) { 4 }
          let(:expected_message) { 'Forgot to ask: How are you?' }
          it { should respond_with_message expected_message }
          it { should_not have_enqueued_job.on_queue('mailers') }
        end

        describe 'with an `email`' do
          let(:params) { { email: 'contributor@example.org' } }
          it { should_not respond_with_message }
          it {
            should have_enqueued_job.on_queue('mailers').with(
              'Mailer',
              'new_message_email',
              'deliver_now',
              {
                params: {
                  mail: { to: 'contributor@example.org', message_stream: 'outbound' },
                  text: 'Forgot to ask: How are you?',
                  headers: { "message-id": anything, references: /#{the_request.id}/ }
                },
                args: []
              }
            )
          }
        end
      end
    end
  end
end
