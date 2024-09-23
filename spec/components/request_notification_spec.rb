# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestNotification::RequestNotification, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { request_for_info: request_for_info } }
  let(:request_for_info) { create(:request) }

  it { should have_css('.RequestNotification', visible: :hidden) }
end
