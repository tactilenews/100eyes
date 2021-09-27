# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::Notifications, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { notifications: [] } }
  it { should have_css('.Notifications') }
end
