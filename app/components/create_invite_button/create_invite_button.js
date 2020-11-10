import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

const SUCCESS_NOTIFICATION_DURATION = 2000;

export default class extends Controller {
  static targets = ['button', 'label', 'loading', 'success'];

  copyLink() {
    if (this.buttonTarget.disabled) {
      return;
    }

    this.buttonTarget.disabled = true;
    this.labelTarget.hidden = true;
    this.loadingTarget.hidden = false;

    Rails.ajax({
      url: `/onboarding/invite`,
      type: 'POST',
      success: ({ url }) => {
        navigator.clipboard.writeText(url).then(() => this.onCopy());
      },
    });
  }

  onCopy() {
    this.loadingTarget.hidden = true;
    this.successTarget.hidden = false;

    setTimeout(() => {
      this.buttonTarget.disabled = false;
      this.labelTarget.hidden = false;
      this.successTarget.hidden = true;
    }, SUCCESS_NOTIFICATION_DURATION);
  }
}
