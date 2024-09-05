# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Footer::Footer, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:organization) { create(:organization) }
  let(:params) { { organization: organization } }
  it { should have_css('.Footer') }
end
