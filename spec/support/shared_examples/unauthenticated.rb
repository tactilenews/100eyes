# frozen_string_literal: true

RSpec.shared_examples 'unauthenticated' do
  context 'when not logged in' do
    it 'redirects to the sign in path' do
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
