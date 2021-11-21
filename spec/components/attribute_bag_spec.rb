# frozen_string_literal: true

RSpec.describe AttributeBag do
  let(:attrs) { {} }
  let(:bag) { described_class.new(**attrs) }

  describe '==' do
    let(:bag) { AttributeBag.new(foo: 'bar', bar: 'baz') }
    subject { bag == other_bag }

    context 'given bags with same attributes' do
      let(:other_bag) { AttributeBag.new(bar: 'baz', foo: 'bar') }
      it { should be(true) }
    end

    context 'given bags with different attributes' do
      let(:other_bag) { AttributeBag.new(bar: 'baz') }
      it { should be(false) }
    end
  end

  describe 'to_s' do
    subject { bag.to_s }
    let(:attrs) { { type: :button } }

    it { should eq('type="button"') }

    it 'returns html-safe string' do
      expect(subject.html_safe?).to be(true)
    end

    context 'with nested attributes' do
      let(:attrs) { { data: { controller: 'copy-button', text: 'Lorem Ipsum' } } }

      it { should eq('data-controller="copy-button" data-text="Lorem Ipsum"') }
    end
  end

  describe 'to_hash' do
    subject { bag.to_hash }
    let(:attrs) { { type: :button } }

    it { should eq({ type: :button }) }
  end

  describe 'merge' do
    subject { bag.merge(**additional_attrs).to_hash }
    let(:attrs) { { type: :button } }
    let(:additional_attrs) { { id: 'form-action' } }

    it { should eq({ type: :button, id: 'form-action' }) }

    it 'does not manipulate original bag' do
      bag.merge(**additional_attrs)
      expect(bag.to_hash).to eq({ type: :button })
    end

    context 'with nested attributes' do
      let(:attrs) { { data: { controller: 'copy-button' } } }
      let(:additional_attrs) { { data: { text: 'Lorem Ipsum' } } }
      it { should eq({ data: { controller: 'copy-button', text: 'Lorem Ipsum' } }) }
    end

    context 'with class attribute' do
      let(:attrs) { { class: 'Button' } }
      let(:additional_attrs) { { class: 'visually-hidden' } }

      it { should eq({ class: 'Button visually-hidden' }) }

      it 'does not manipulate bag' do
        bag.merge(class: 'visually-hidden')
        expect(bag.to_hash).to eq({ class: 'Button' })
      end
    end
  end

  describe 'defaults' do
    subject { bag.defaults(**default_attrs).to_hash }
    let(:default_attrs) { { type: :button } }

    it { should eq({ type: :button }) }

    context 'with attributes given explicitly' do
      let(:attrs) { { type: :submit } }
      let(:default_attrs) { { type: :button, id: 'form-action' } }

      it { should eq({ type: :submit, id: 'form-action' }) }
    end
  end

  describe 'slice' do
    subject { bag.slice(*slice_attrs).to_hash }
    let(:attrs) { { type: :button, id: 'form-action' } }
    let(:slice_attrs) { [] }

    it { should be_empty }

    context 'with slice attributes' do
      let(:slice_attrs) { [:type] }
      it { should eq({ type: :button }) }
    end
  end

  describe 'except' do
    subject { bag.except(*except_attrs).to_hash }
    let(:attrs) { { type: :button, id: 'form-action' } }
    let(:except_attrs) { [] }

    it { should eq(attrs) }

    context 'with except attributes' do
      let(:except_attrs) { [:type] }
      it { should eq({ id: 'form-action' }) }
    end
  end
end
