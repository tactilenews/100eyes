# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'users/index', type: :view do
  before(:each) do
    assign(:users, create_list(:user, 2))
  end

  it 'renders a list of users' do
    render
  end
end
