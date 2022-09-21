# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self
  policy.img_src     :self, :blob, :data
  policy.object_src  :none
  if Rails.env.development?
    policy.script_src :self, :https, :unsafe_eval, :unsafe_inline
  else
    policy.script_src :self, :https
  end
  Rails.application.config.content_security_policy_nonce_generator = -> (request) do
    # use the same csp nonce for turbo requests
    if request.env['HTTP_TURBO_REFERRER'].present?
      request.env['HTTP_X_TURBO_NONCE']
    else
      SecureRandom.base64(16)
    end
  end
  # TODO: `unsafe_inline` can be removed once this PR lands in the next
  # Turbo release: https://github.com/hotwired/turbo/pull/501
  policy.style_src :self, :unsafe_inline

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end


# Set the nonce only to specific directives
Rails.application.config.content_security_policy_nonce_directives = []

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
