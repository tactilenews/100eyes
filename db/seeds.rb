# frozen_string_literal: true

# rubocop:disable Rails/Output
password = 'go3LS4gvPuuSoq2m0B2n'
otp_secret_key = 'THDBCRGPERS75F7IDDLISUDC6N2YYG3V'
user = User.create_or_find_by(email: 'redaktion@tactile.news', password: password, admin: true, otp_secret_key: otp_secret_key)

puts "User with email #{user.email}"
# rubocop:enable Rails/Output
