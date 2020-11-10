# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchResult::SearchResult, type: :component do
  subject { render_inline(described_class.new(result: result)) }
  let(:contributor) { create(:contributor, id: 1) }
  let(:the_request) { create(:request, id: 1) }

  describe 'given a message' do
    let(:result) { create(:message, sender: contributor, request: the_request, text: 'I am a message') }
    it {
      should have_link('I am a message', href: '/contributors/1/requests/1')
    }
  end

  describe 'given a contributor' do
    let(:result) { contributor }
    it { should have_link('John Doe', href: '/contributors/1') }
  end
end
