# frozen_string_literal: true

RSpec.shared_examples 'protected' do
  context 'with a user of another organization' do
    it 'renders not found ' do
      expect(response).to be_not_found
    end
  end
end
