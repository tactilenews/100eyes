import { Controller } from 'stimulus';
import Rails from '@rails/ujs';
import sanitize from '../../../frontend/helpers/sanitize.js';

const template = ({ message, notes }) => {
  message = sanitize(message) || '<span class="Placeholder">Frage</span>';
  return message;
};

export default class extends Controller {
  static targets = ['preview', 'message', 'membersCount'];

  connect() {
    this.updatePreview();
    this.updateMembersCount();
  }

  updatePreview() {
    const data = {
      message: this.messageTarget.value,
    };

    this.previewTarget.innerHTML = template(data);
  }

  updateMembersCount(event) {
    if (!event || event.detail.tags.length <= 0) {
      this.membersCountTarget.hidden = true;
      return;
    }

    const messageTemplates = JSON.parse(this.data.get('members-count-message'));
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
