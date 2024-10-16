# frozen_string_literal: true

require 'administrate/field/base'

class SetupSignalLinkField < Administrate::Field::Base
  def setup_signal_url
    "/#{resource.id}/signal/register"
  end

  def signal_server_phone_number
    data
  end
end
