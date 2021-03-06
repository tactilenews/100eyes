import { Controller } from 'stimulus';
import Rails from '@rails/ujs';
import sanitize from '../../../frontend/helpers/sanitize.js';

const template = ({ message, fallback }) => {
  message = sanitize(message) || fallback;
  return message;
};

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

  updatePreview() {
    this.previewTarget.innerHTML = template({
      message: this.messageTarget.value,
      fallback: this.previewFallbackValue,
    });
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
