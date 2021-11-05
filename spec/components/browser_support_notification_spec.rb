# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BrowserSupportNotification::BrowserSupportNotification, type: :component do
  subject { render_inline(described_class.new) }
  let(:user_agent) { nil }

  before(:each) { allow(request).to receive(:user_agent).and_return(user_agent) }

  context 'if user agent is a modern browser' do
    # Google Chrome / macOS
    let(:user_agent) do
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36'
    end

    it { should_not have_css('.BrowserSupportNotification') }
  end

  context 'if user agent is an unsupported browser' do
    # Safari 12 / macOS
    let(:user_agent) do
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15'
    end

    it { should have_css('.BrowserSupportNotification') }
  end
end
