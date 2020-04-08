require 'test_helper'

class PageWrapperTest < ViewComponentTestCase
  include ComponentHelper

  test 'render wrapper' do
    component_inline('page_wrapper') { 'Content' }
    assert_text('Content')
    assert_selector('div.c-page-wrapper')
  end
end
