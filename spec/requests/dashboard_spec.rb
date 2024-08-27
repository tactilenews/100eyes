# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/{organization_id}/dashboard', type: :request do

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  it_behaves_like "protected" do
    before { get organization_dashboard_path(organization, as: create(:user))}
  end

  it_behaves_like "unauthenticated" do
     before { get organization_dashboard_path(organization) }
  end

  context "with a user of the organization" do
    subject { -> { get organization_dashboard_path(organization, as: user)} }

    it "renders the dashboard for the organizations user" do
      subject.call
      expect(response).to be_successful
    end

    it "counts the active contributors for the organization" do
      contributor = create_list(:contributor, 3, organization: organization)
      other_contributor = create(:contributor)
      subject.call
      expect(page).to have_content "3 aktive Mitglieder"
    end

    it "counts the requests for the organization" do
      contributor = create_list(:request, 3, organization: organization)
      other_contributor = create(:request)
      subject.call
      expect(page).to have_content "3 Fragen gestellt"
    end

    it "counts the replies for the organization" do
      request = create(:request, organization: organization)
      replies = create_list(:message, 3, request: request)
      other_message = create(:message)
      subject.call
      expect(page).to have_content "3 empfangene Nachrichten"
    end

    it "calculates the engagement metric for the organization only" do
      request = create(:request, organization: organization)
      contributors = create_list(:contributor, 2, organization: organization)
      contributor = create(:contributor)
      replies = create(:message, :inbound, sender: contributors[0], organization: organization)
      other_replies = create(:message, :inbound, sender: contributors[1])
      subject.call
      expect(page).to have_content "50% Interaktionsquote"
    end


    it "doesn't include activity notifications for other organizations" do
    end

    it "includes activity notifications for the organization" do
    end
  end
end
