# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResultComponent::SearchResultComponent, type: :component do
  subject { render_inline(described_class.new(result: result)) }
  let(:user) { create(:user, id: 1) }
  let(:the_request) { create(:request, id: 1) }

  describe 'given a reply' do
    let(:result) { create(:reply, user: user, request: the_request, text: 'I am a reply') }
    it {
      should have_link('I am a reply', href: '/users/1/requests/1')
    }
  end

  describe 'given a user' do
    let(:result) { user }
    it { should have_link('John Doe', href: '/users/1') }
  end
end
