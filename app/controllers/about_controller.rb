# frozen_string_literal: true

class AboutController < ApplicationController
  skip_before_action :set_organization

  layout 'minimal'

  def index; end
end
