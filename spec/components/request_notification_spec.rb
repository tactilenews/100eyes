# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestNotification::RequestNotification, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { request: request } }
  let(:request) { build(:request) }

  it { should have_css('.RequestNotification', visible: :hidden) }
end
