# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StepsList::StepsList, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { steps: [] } }

  it { is_expected.to have_css('.StepsList') }
end
