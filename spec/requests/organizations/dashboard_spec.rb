# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/:organization_id/dashboard', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization]) }

  it_behaves_like 'protected' do
    before { get organization_dashboard_path(organization, as: create(:user)) }
  end

  it_behaves_like 'unauthenticated' do
    before { get organization_dashboard_path(organization) }
  end

  context 'with a user of the organization' do
    subject { -> { get organization_dashboard_path(organization, as: user) } }

    it 'renders the dashboard for the organizations user' do
      subject.call
      expect(response).to be_successful
    end

    it 'counts the active contributors for the organization' do
      create_list(:contributor, 3, organization: organization)
      create(:contributor)
      subject.call
      expect(page).to have_content '3 aktive Mitglieder'
    end

    it 'counts the requests for the organization' do
      create_list(:request, 3, organization: organization)
      create(:request)
      subject.call
      expect(page).to have_content '3 Fragen gestellt'
    end

    it 'counts the replies for the organization' do
      create_list(:message, 3, :inbound, organization: organization)
      create(:message, :inbound) # other message
      create(:message, :outbound) # shouldn't be counted
      subject.call
      expect(page).to have_content '3 empfangene Nachrichten'
    end

    it 'calculates the engagement metric for the organization only' do
      contributors = create_list(:contributor, 2, organization: organization)
      create(:contributor) # other contributor
      create(:message, :inbound, sender: contributors[0], organization: organization)
      create(:message, :inbound, sender: contributors[1]) # other replies
      subject.call
      expect(page).to have_content '50% Interaktionsquote'
    end
  end
end
