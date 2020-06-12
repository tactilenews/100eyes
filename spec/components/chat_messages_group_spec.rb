# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessagesGroup::ChatMessagesGroup, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:user) { create(:user) }
  let(:message) { create(:message) }
  let(:params) { { messages: [message], user: user } }

  it { should have_css('.ChatMessagesGroup') }
end
