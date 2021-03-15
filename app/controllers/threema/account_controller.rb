# frozen_string_literal: true

class Threema::AccountController < ApplicationController
  def credits
    account = Threema::Account.new(threema: Threema.new)
    begin
      render json: { credits: account.credits }
    rescue Unauthorized
      render json: { credits: nil }
    end
  end
end
