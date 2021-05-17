import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

const SUCCESS_NOTIFICATION_DURATION = 2000;

export default class extends Controller {
  static values = { copy: String, url: String, key: String };
  static targets = ['label', 'loading', 'success'];

  copy() {
    if (this.element.disabled) {
      return;
    }

    // If a static copy value is provided, write that to the clipboard
    if (this.hasCopyValue) {
      return this.writeToClipboard(this.copyValue);
    }

    // Otherwise, if a URL is provided, fetch and copy from the URL
    if (this.hasUrlValue) {
      this.copyFromUrl();
    }
  }

  copyFromUrl() {
    if (!this.keyValue) {
      return;
    }

    this.element.disabled = true;
    this.element.dataset.state = 'loading';

    Rails.ajax({
      url: this.urlValue,
      type: 'POST',
      success: response => {
        this.writeToClipboard(response[this.keyValue]);
      },
    });
  }

  writeToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => this.onCopy());
  }

  onCopy() {
    this.element.disabled = false;
    this.element.dataset.state = 'success';

    setTimeout(() => {
      this.element.dataset.state = 'ready';
    }, SUCCESS_NOTIFICATION_DURATION);
  }
}
