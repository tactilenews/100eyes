# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Markdown::Markdown, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { raw: '' } }

  it { is_expected.to have_css('.Markdown') }
end
