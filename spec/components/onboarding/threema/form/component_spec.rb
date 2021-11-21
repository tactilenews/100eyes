# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::Threema::Form::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { build(:contributor) }
  let(:params) { { contributor: contributor, jwt: 'JWT' } }

  it { should have_css('.Onboarding-Threema-Form') }
  it { should have_link(href: Setting.onboarding_data_protection_link) }
end
