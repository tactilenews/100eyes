# frozen_string_literal: true

# rubocop:disable Rails/Output
password = 'go3LS4gvPuuSoq2m0B2n'
user = User.create_or_find_by(email: 'redaktion@tactile.news',
                              password: password,
                              password_confirmation: password,
                              confirmed_at: Time.current)

puts "User with email #{user.email}"
# rubocop:enable Rails/Output
