# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe '/:organization_id/contributors', type: :request do
  let(:organization) { create(:organization) }
  let!(:contributor) { create(:contributor, organization: organization) }
  let(:the_request) { create(:request, organization: organization) }
  let(:user) { create(:user, organizations: [organization]) }

  describe 'GET /index' do
    let!(:other_organizations_contributor) { create(:contributor, first_name: 'WhatAName') }
    let!(:other_inactive_contributor) { create(:contributor, :inactive) }
    let!(:other_unsubscribed_contributor) { create(:contributor, :unsubscribed) }

    before { get organization_contributors_url(organization, as: user) }

    it 'should be successful' do
      expect(response).to be_successful
    end

    it 'contains only the contributors from the organization' do
      expect(page).to have_content contributor.first_name

      expect(page).to have_content('Aktiv 1')
      expect(page).to have_content('Inaktiv 0')
      expect(page).to have_content('Abbestellt 0')

      expect(page).not_to have_content other_organizations_contributor.first_name
    end
  end

  describe 'GET /show' do
    subject { -> { get organization_contributor_url(organization, contributor, as: user) } }

    it 'should be successful' do
      subject.call
      expect(response).to be_successful
    end

    context 'with contributors of other organizations' do
      let!(:other_organizations_contributor) { create(:contributor, first_name: 'WhatAName') }

      it 'renders not found' do
        get organization_contributor_url(organization, create(:contributor), as: user)
        expect(response).to be_not_found
      end

      it 'doesn\'t have the other contributor in the sidebar' do
        subject.call
        expect(page).not_to have_content other_organizations_contributor.first_name
      end
    end
  end

  describe 'GET /count' do
    subject { -> { get count_organization_contributors_path(organization, tag_list: ['teacher'], as: user) } }

    let!(:teachers) { create_list(:contributor, 2, tag_list: 'teacher', organization: organization) }
    let!(:other_teachers) { create_list(:contributor, 2, tag_list: 'teacher') }

    it 'returns count of contributors with a specific tag within the organization' do
      subject.call
      expect(response.body).to eq({ count: 2 }.to_json)
    end

    context 'given non-active contributors' do
      before do
        create(:contributor, tag_list: 'teacher', deactivated_at: 1.day.ago, organization: organization)
        create(:contributor, tag_list: 'teacher', unsubscribed_at: 1.day.ago, organization: organization)
        subject.call
      end

      it 'returns the count of contributors with a specific tag for active contributors' do
        expect(response.body).to eq({ count: 2 }.to_json)
      end
    end
  end

  describe 'GET /conversations' do
    it 'returns the conversation of the contributor' do
      received_message = create(:message, text: 'the received message', recipient: contributor,
                                          request: the_request)
      sent_message = create(:message, text: 'the sent message', request: the_request, sender: contributor)
      get conversations_organization_contributor_path(organization, contributor, as: user)
      expect(response).to be_successful
      parsed = Capybara::Node::Simple.new(response.body)
      expect(parsed).to have_text(received_message.text)
      expect(parsed).to have_text(sent_message.text)
    end

    context 'for contributors of other organizations' do
      it 'renders not found' do
        get conversations_organization_contributor_path(organization, create(:contributor), as: user)
        expect(response).to be_not_found
      end
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
        additional_email: 'zora@zimmermann.de',
        tag_list: 'programmer,student'
      }
    end

    subject { -> { patch organization_contributor_url(organization, contributor, as: user), params: { contributor: new_attrs } } }

    context 'for contributors of other organizations' do
      it 'renders not found' do
        patch organization_contributor_url(organization, create(:contributor), as: user), params: { contributor: new_attrs }
        expect(response).to be_not_found
      end
    end

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
      expect(contributor.additional_email).to eq('zora@zimmermann.de')
      expect(contributor.tag_list).to match_array(%w[programmer student])
    end

    it 'does not update the deactivated_by_user_id' do
      expect { subject.call }.not_to(change { contributor.reload.deactivated_by_user_id })
    end

    context 'removing tags' do
      let(:updated_attrs) do
        { tag_list: 'ops' }
      end
      let(:contributor) { create(:contributor, organization: organization, tag_list: %w[dev ops]) }

      it 'is supported' do
        patch organization_contributor_url(organization, id: contributor.id, as: user), params: { contributor: updated_attrs }
        contributor.reload
        expect(contributor.tag_list).to eq(['ops'])
        expect(organization.contributors.all_tags.count).to eq(1)
      end
    end

    it 'redirects to the contributor' do
      subject.call
      expect(response).to redirect_to(organization_contributor_url(organization, contributor))
    end

    it 'shows success message' do
      subject.call
      expect(flash[:success]).to eq('Informationen zu Zora Zimmermann gespeichert')
    end

    context 'given a manually created contributor' do
      let(:contributor) do
        create(:contributor, :skip_validations, data_processing_consent: false, first_name: 'John', organization: organization)
      end

      it 'updates contributor' do
        expect { subject.call }.to(change { contributor.reload.first_name }.from('John').to('Zora'))
      end

      it 'does not change data processing consent' do
        expect { subject.call }.to_not(change { contributor.data_processing_consent })
      end
    end

    context 'with validations failing' do
      let(:new_attrs) { { email: 'INVALID' } }

      it do
        subject.call

        parsed = Capybara::Node::Simple.new(response.body)
        text = I18n.t('contributor.invalid', name: contributor.name)

        expect(parsed).to have_css('.Notification', text: text)
      end
    end

    context 'given a Threema contributor' do
      let(:threema) { instance_double(Threema) }
      let(:threema_lookup_double) { instance_double(Threema::Lookup) }
      let(:contributor) { create(:contributor, :skip_validations, threema_id: 'VALID123', organization: organization) }
      let(:new_attrs) { { threema_id: 'INVALID!' } }

      before do
        allow(Threema).to receive(:new).and_return(threema)
        allow(Threema::Lookup).to receive(:new).with({ threema: threema }).and_return(threema_lookup_double)
        allow(threema_lookup_double).to receive(:key).and_return(nil)
      end

      it 'displays validation errors' do
        subject.call
        parsed = Capybara::Node::Simple.new(response.body)
        threema_id_field = parsed.find('#contributor-threema-settings')
        expect(threema_id_field).to have_text('Threema ID ist ungültig, bitte überprüfen.')
      end

      it 'does not update the contributor' do
        expect { subject.call }.not_to change(contributor, :threema_id)
      end

      it 'has 422 status code' do
        subject.call
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'deactivating contributor' do
      let(:new_attrs) { { active: 'off' } }

      it 'sets the deactivated_at attribute' do
        expect { subject.call }.to change { contributor.reload.deactivated_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it 'sets the deactivate_by_user to current_user' do
        expect { subject.call }.to change { contributor.reload.deactivated_by_user }.from(nil).to(user)
      end
    end

    context 'reactivating deactivated contributor' do
      let(:new_attrs) { { active: 'on' } }

      before { contributor.update(deactivated_at: Time.current, deactivated_by_user: user) }

      it 'returns the deactivated_at attribute to nil' do
        expect { subject.call }.to change { contributor.reload.deactivated_at }.from(kind_of(ActiveSupport::TimeWithZone)).to(nil)
      end

      it 'returns the deactivate_by_user to nil' do
        expect { subject.call }.to change { contributor.reload.deactivated_by_user }.from(user).to(nil)
      end
    end
  end

  describe 'POST /message', telegram_bot: :rails do
    subject do
      lambda do
        post message_organization_contributor_url(organization, contributor, as: user),
             params: { message: { text: 'Forgot to ask: How are you?' } }
      end
    end

    context 'for contributors of other organizations' do
      it 'renders not found' do
        post message_organization_contributor_url(organization, create(:contributor), as: user),
             params: { message: { text: 'Forgot to ask: How are you?' } }
        expect(response).to be_not_found
      end
    end

    describe 'given a contributor of the organization' do
      let(:params) { {} }
      let(:contributor) { create(:contributor, :telegram_contributor, organization: organization, **params) }

      describe 'given the contributor has not received any requests' do
        it 'creates the message' do
          expect { subject.call }.to change(Message, :count).by(1)
        end
      end

      describe 'given an active request' do
        before(:each) { create(:message, :outbound, request: the_request, recipient: contributor) }

        it { is_expected.to change(Message, :count).by(1) }

        describe 'response' do
          before(:each) { subject.call }
          let(:newest_message) { Message.reorder(created_at: :desc).first }

          it do
            expect(response)
              .to redirect_to(newest_message.chat_message_link)
          end

          it 'schedules a job to send out the message' do
            expect(TelegramAdapter::Outbound::Text).to have_been_enqueued.with(
              contributor_id: newest_message.recipient.id,
              text: newest_message.text,
              message: newest_message
            )
          end
        end
      end
    end
  end
end
