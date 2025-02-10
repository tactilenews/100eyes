# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessageHeader::ChatMessageHeader, type: :component do
  subject { render_inline(component) }

  let(:component) { described_class.new(**params) }
  let(:params) { { message: message } }

  describe 'header_content' do
    let(:sent_by_text) { strip_tags(I18n.t('components.chat_message.sent_by_x_at', name: name, date: I18n.l(message.updated_at)).strip) }
    let(:conversations_path) { "/#{message.organization.id}/contributors/#{message.sender.id}/conversations" }

    context 'given a message is a reply' do
      let(:contributor) { create(:contributor, first_name: 'Joaquin') }
      let(:message) { create(:message, :inbound, :with_request, sender: contributor) }
      let(:name) { 'Joaquin' }

      context 'given on the conversations path' do
        before do
          allow(component).to receive(:current_page?).with(conversations_path).and_return(true)
        end

        context 'given attached to a request' do
          it 'renders the sent by text' do
            expect(subject).to have_content(sent_by_text)
          end

          it 'renders the link to the request' do
            expect(subject).to have_link(message.request.title,
                                         href: "/#{message.organization.id}/requests/#{message.request.id}#message-#{message.id}")
          end
        end

        context 'given the request is blank' do
          before { message.update(request: nil) }

          it 'renders only the sent by text' do
            expect(subject).to have_content(sent_by_text)
            expect(subject).not_to have_link
          end
        end
      end

      context 'given on any other path' do
        before do
          allow(component).to receive(:current_page?).with(conversations_path).and_return(false)
        end

        it 'renders a link to the conversations path' do
          expect(subject).to have_link(sent_by_text, href: "#{conversations_path}#message-#{message.id}")
        end
      end
    end

    context 'given a message is not a reply' do
      let(:message) { create(:message, :outbound, :with_request, sender: user) }
      let(:user) { create(:user, first_name: 'Melinda') }
      let(:name) { 'Melinda' }

      it 'renders the sent by text' do
        expect(subject).to have_content(sent_by_text)
      end

      it 'renders the link to the request' do
        expect(subject).to have_link(message.request.title,
                                     href: "/#{message.organization.id}/requests/#{message.request.id}#message-#{message.id}")
      end
    end
  end
end
