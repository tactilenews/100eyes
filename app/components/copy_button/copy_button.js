import { Controller } from 'stimulus';
import * as clipboard from 'clipboard-polyfill/text';
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

    /* Some browser require that copying to the clipboard (via
     * document.execCommand('copy') which is used by polyfill)
     * happens in response to a user interaction, e.g. clicking
     * a button. This doesn't work when copying in a callback
     * though, e.g. in response to an AJAX request. It does
     * however work when calling the method in an interval that
     * has been set as a direct response to the user interaction.
     */
    let url = null;

    Rails.ajax({
      url: this.urlValue,
      type: 'POST',
      success: response => {
        url = response[this.keyValue];
      },
    });

    const interval = window.setInterval(() => {
      if (!url) {
        return;
      }

      this.writeToClipboard(url);
      window.clearInterval(interval);
    }, 100);
  }

  writeToClipboard(text) {
    clipboard.writeText(text).then(() => this.onCopy());
  }

  onCopy() {
    this.element.disabled = false;
    this.element.dataset.state = 'success';

    setTimeout(() => {
      this.element.dataset.state = 'ready';
    }, SUCCESS_NOTIFICATION_DURATION);
  }
}
