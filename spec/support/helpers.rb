# frozen_string_literal: true

module Helpers
  def will(matcher)
    expect { subject.call }.to(matcher)
  end
end
