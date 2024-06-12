# frozen_string_literal: true

require 'administrate/field/base'

class OrganizationLinkField < Administrate::Field::Base
  def organizations_url
    "/#{data}/dashboard"
  end

  def slug
    data
  end
end
