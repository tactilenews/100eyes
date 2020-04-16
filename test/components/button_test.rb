# frozen_string_literal: true

require 'test_helper'

class ButtonTest < ViewComponentTestCase
  test 'render content' do
    component_inline('button') { 'Button label' }
    assert_text('Button label')
  end

  test 'optionally set content via label parameter' do
    component_inline('button', label: 'Button label')
    assert_text('Button label')
  end

  test 'render primary button' do
    component_inline('button')
    assert_selector('.c-button.c-button--primary')
  end

  test 'render secondary button' do
    component_inline('button', style: 'secondary')
    assert_selector('.c-button.c-button--secondary')
  end

  test 'use optional type' do
    component_inline('button', type: 'submit')
    assert_selector('.c-button[type="submit"]')
  end

  test 'use a tag if given link' do
    component_inline('button', link: '#')
    assert_selector('a.c-button[href="#"]')
  end
end
