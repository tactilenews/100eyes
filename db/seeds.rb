# frozen_string_literal: true

# rubocop:disable Rails/Output
password = 'go3LS4gvPuuSoq2m0B2n'
otp_secret_key = 'THDBCRGPERS75F7IDDLISUDC6N2YYG3V'

organization = Organization.create_or_find_by(name: '100eyes',
                                              upgrade_discount: 10,
                                              business_plan: BusinessPlan.where.not(
                                                valid_from: nil, valid_until: nil
                                              ).first)
admin = User.create_or_find_by(email: 'redaktion@tactile.news', first_name: 'Dennis', last_name: 'Schröder', password: password,
                               admin: true, otp_secret_key: otp_secret_key)
user = User.create_or_find_by(email: 'contact-person@example_organization.org', first_name: 'ConactFor', last_name: 'Organization',
                              password: password, otp_secret_key: otp_secret_key, organization: organization)
organization.update(contact_person: user)
puts "Organization with name #{organization.name}"
puts "Admin with email #{admin.email}"
puts "User with email #{user.email}"
# rubocop:enable Rails/Output
