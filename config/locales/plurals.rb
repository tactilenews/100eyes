# frozen_string_literal: true

{
  de: {
    i18n: {
      plural: {
        keys: %i[one two other],
        rule: lambda { |n|
          case n
          when 1
            :one
          when 2
            :two
          else
            :other
          end
        }
      }
    }
  }
}
