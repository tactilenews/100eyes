import { Controller } from 'stimulus';

const SUCCESS_NOTIFICATION_DURATION = 2000;

export default class extends Controller {
  static targets = ['button', 'label', 'success'];
  static values = {
    secretKey: String,
  };

  copyText() {
    if (this.buttonTarget.disabled) {
      return;
    }

    this.buttonTarget.disabled = true;
    this.labelTarget.hidden = true;

    navigator.clipboard
      .writeText(this.secretKeyValue)
      .then(() => this.onCopy());
  }

  onCopy() {
    this.successTarget.hidden = false;

    setTimeout(() => {
      this.buttonTarget.disabled = false;
      this.labelTarget.hidden = false;
      this.successTarget.hidden = true;
    }, SUCCESS_NOTIFICATION_DURATION);
  }
}
