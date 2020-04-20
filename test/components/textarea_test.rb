# frozen_string_literal: true

require 'test_helper'

class TextareaTest < ViewComponentTestCase
  test 'render textarea' do
    component_inline('textarea')
    assert_selector('textarea.c-textarea')
  end

  test 'render id' do
    component_inline('textarea', id: 'hello-world')
    assert_selector('textarea#hello-world')
  end

  test 'render value' do
    component_inline('textarea', value: 'Hello World!')
    assert_text('Hello World!')
  end

  test 'set required attribute' do
    component_inline('textarea', required: true)
    assert_selector('textarea[required]')
  end

  test 'render placeholder' do
    component_inline('textarea', placeholder: 'Hello World!')
    assert_selector('textarea[placeholder="Hello World!"]')
  end
end
