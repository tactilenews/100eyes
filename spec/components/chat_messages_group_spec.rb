# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessagesGroup::ChatMessagesGroup, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor) }
  let(:message) { create(:message) }
  let(:contributor_request) { create(:request, id: 1) }
  let(:params) { { organization: organization, messages: [message], contributor: contributor, request: contributor_request } }

  it { should have_css('.ChatMessagesGroup') }
end
