import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

const POLLING_INTERVAL = 1000 * 30;

export default class extends Controller {
  static targets = ['text'];

  connect() {
    this.lastUpdatedAt = this.data.get('last-updated-at');
    this.messageTemplate = JSON.parse(this.data.get('message-template'));
    this.fetchMessages();
    setInterval(() => this.fetchMessages(), POLLING_INTERVAL);
  }

  fetchMessages() {
    Rails.ajax({
      url: `/requests/${this.data.get('id')}/notifications`,
      type: 'GET',
      data: new URLSearchParams({
        last_updated_at: this.lastUpdatedAt,
      }).toString(),
      success: ({ message_count }) => {
        if (message_count == 0) {
          return;
        }

        this.element.hidden = false;

        if (message_count == 1) {
          this.textTarget.innerHTML = this.messageTemplate.one;
          return;
        }

        this.textTarget.innerHTML = this.messageTemplate.other.replace(
          '{count}',
          message_count
        );
      },
    });
  }
}
