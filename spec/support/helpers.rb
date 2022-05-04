# frozen_string_literal: true

module Helpers
  def it_should(matcher)
    expect { subject.call }.to(matcher)
  end
end
