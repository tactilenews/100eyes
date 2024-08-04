# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Form::Form, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { create(:contributor) }
  let(:params) { { model: [contributor.organization, contributor] } }

  it { should have_css("form[action='/#{contributor.organization_id}/contributors/#{contributor.id}']") }
end
