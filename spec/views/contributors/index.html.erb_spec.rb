# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'contributors/index', type: :view do
  before do
    assign(:contributors, create_list(:contributor, 2))
    assign(:tag_list, [])
  end

  it 'renders a list of contributors' do
    render
  end
end
