# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessagesGroup::ChatMessagesGroup, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:contributor) { create(:contributor) }
  let(:message) { create(:message) }
  let(:params) { { messages: [message], contributor: contributor } }

  it { should have_css('.ChatMessagesGroup') }
end
