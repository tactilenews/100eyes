# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributors::IndexData do

  let(:organization) { create(:organization) }
  let(:active_contributor) { create(:contributor, organization: organization) }
  let(:inactive_contributor) { create(:contributor, :inactive, organization: organization) }
  let(:other_organizations_contributor) { }

  let(:contributor_params) { {state: active, tag_list: ["foo, bar"] } }

  subject { Contributors::IndexData.new(organization, contributor_params) }

  describe ".active_count" do
    it "does include the active contributors in the organization only" do

    end
  end

end
