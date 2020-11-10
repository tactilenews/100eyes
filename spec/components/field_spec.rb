# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Field::Field, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { build(:contributor) }
  let(:params) { { object: contributor, id: :name, label: 'Example' } }
  it { should have_css('.Field') }
end
