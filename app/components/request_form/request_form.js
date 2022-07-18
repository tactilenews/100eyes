import { Controller } from '@hotwired/stimulus';
import Rails from '@rails/ujs';
import sanitize from '../../assets/javascript/helpers/sanitize.js';
import replacePlaceholder from '../../assets/javascript/helpers/replace-placeholder.js';

export default class extends Controller {
  static targets = ['preview', 'message', 'membersCount'];
  static values = {
    membersCountMessage: String,
    previewFallback: String,
  };

  connect() {
    this.updatePreview();
    this.updateMembersCount();
  }

  insertPlaceholderAtCursor() {
    console.log('im here baby');
    const placeholder = '{{FIRST_NAME}}'
    const [start, end] = [this.messageTarget.selectionStart, this.messageTarget.selectionEnd];
    console.log("im here, what's next");

    this.messageTarget.setRangeText(placeholder, start, end, 'end');
    const event = new Event('input', { bubbles: true });
    this.messageTarget.dispatchEvent(event)
    this.messageTarget.focus();

  }

  updatePreview() {
    let message = sanitize(this.messageTarget.value);
    message = message || this.previewFallbackValue;
    message = replacePlaceholder(message, 'FIRST_NAME', 'Max');
    this.previewTarget.innerHTML = message;
  }

  updateMembersCount(event) {
    if (!event || event.detail.tags.length <= 0) {
      this.membersCountTarget.hidden = true;
      return;
    }

    const messageTemplates = JSON.parse(this.membersCountMessageValue);
    const tags = event.detail.tags;

    Rails.ajax({
      url: '/contributors/count',
      type: 'GET',
      data: new URLSearchParams({ tag_list: tags }).toString(),
      success: ({ count }) => {
        this.membersCountTarget.hidden = false;

        if (count == 1) {
          this.membersCountTarget.innerHTML = messageTemplates.one;
          return;
        }

        const message = messageTemplates.other.replace('%{count}', count);
        this.membersCountTarget.innerHTML = message;
      },
    });
  }
}
