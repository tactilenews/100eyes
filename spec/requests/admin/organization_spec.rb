# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organization management' do
  context 'POST /admin/organizations' do
    subject { -> { post admin_organizations_path(as: user), params: params } }

    let(:business_plan) { create(:business_plan) }
    let(:required_params) do
      {
        organization:
        {
          name: 'Find by my name',
          business_plan_id: business_plan.id,
          project_name: 'NewProject'
        }
      }
    end
    let(:params) { required_params }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, admin: false) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, admin: true) }

      before { user }

      it 'creates the organization' do
        expect { subject.call }.to change(Organization, :count).by(1)
      end

      it 'assigns the business plan to the organization' do
        subject.call
        organization = Organization.find_by(name: 'Find by my name')
        expect(organization.business_plan).to eq(business_plan)
      end

      it "redirect to organization's show page" do
        subject.call
        organization = Organization.find_by(name: 'Find by my name')
        expect(response).to redirect_to(admin_organization_path(organization))
      end

      context 'Email' do
        let(:params) do
          required_params.deep_merge({ organization: { name: 'I have an email',
                                                       email_from_address: 'redaktion@100ey.es' } })
        end

        it 'allows configuration of Email specific attributes' do
          subject.call
          follow_redirect!
          expect(page).to have_content('I have an email')
          expect(page).to have_content('redaktion@100ey.es')
        end
      end

      context 'Telegram' do
        let(:params) do
          required_params.deep_merge({ organization: { telegram_bot_api_key: 'valid_api_key',
                                                       telegram_bot_username: 'unique_username_bot' } })
        end

        it 'allows configuration of Telegram specific attributes' do
          subject.call
          follow_redirect!
          expect(page).to have_content('unique_username_bot')
          expect(page).not_to have_content('valid_api_key')
          organization = Organization.find_by(telegram_bot_username: 'unique_username_bot')
          expect(organization.telegram_bot_api_key).to eq('valid_api_key')
        end
      end

      context 'Threema' do
        let(:params) do
          required_params.deep_merge({ organization: { threemarb_api_identity: '*APIIDENT',
                                                       threemarb_api_secret: 'valid_secret',
                                                       threemarb_private: 'valid_private_key' } })
        end

        it 'allows configuration of Threema specific attributes' do
          subject.call
          follow_redirect!
          expect(page).to have_content('*APIIDENT')
          expect(page).not_to have_content('valid_secret')
          expect(page).not_to have_content('valid_private_key')

          organization = Organization.find_by(threemarb_api_identity: '*APIIDENT')
          expect(organization).to have_attributes(threemarb_api_secret: 'valid_secret', threemarb_private: 'valid_private_key')
        end
      end

      context 'Signal' do
        let(:signal_params) { { signal_server_phone_number: '+4912345678' } }
        let(:params) do
          required_params.deep_merge({ organization: signal_params })
        end

        it 'displays an error if the signal username is not set' do
          subject.call

          expect(page).to have_content('Signal username muss ausgefüllt werden')
        end

        context 'with a valid signal username' do
          let(:params) do
            required_params.deep_merge({ organization: signal_params.merge(signal_username: 'valid_username') })
          end

          it 'allows configuring signal' do
            subject.call
            follow_redirect!

            expect(page).to have_content('+4912345678')

            organization = Organization.find_by(signal_server_phone_number: '+4912345678')
            expect(organization).to have_attributes(signal_params)
          end
        end
      end
    end
  end
end
