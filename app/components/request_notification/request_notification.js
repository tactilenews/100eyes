import { Controller } from '@hotwired/stimulus';
import Rails from '@rails/ujs';

const POLLING_INTERVAL = 1000 * 30;

export default class extends Controller {
  static targets = ['text'];
  static values = {
    lastUpdatedAt: String,
    messageTemplate: String,
    fetchMessagesUrl: String,
  };

  connect() {
    this.messageTemplate = JSON.parse(this.messageTemplateValue);
    this.intervalHandle = setInterval(
      () => this.fetchMessages(),
      POLLING_INTERVAL,
    );
  }

  disconnect() {
    clearInterval(this.intervalHandle);
  }

  fetchMessages() {
    Rails.ajax({
      url: this.fetchMessagesUrlValue,
      type: 'GET',
      data: new URLSearchParams({
        last_updated_at: this.lastUpdatedAtValue,
      }).toString(),
      success: ({ message_count: count }) => this.updateMessageCount(count),
    });
  }

  updateMessageCount(count) {
    if (count == 0) {
      return;
    }

    this.element.hidden = false;

    if (count == 1) {
      this.textTarget.innerHTML = this.messageTemplate.one;
      return;
    }

    const message = this.messageTemplate.other.replace('{count}', count);
    this.textTarget.innerHTML = message;
  }
}
