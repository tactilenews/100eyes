# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Form::Form, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, organization: organization) }
  let(:params) { { model: [organization, contributor] } }

  it { should have_css("form[action='/#{organization.id}/contributors/#{contributor.id}']") }
end
