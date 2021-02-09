import { Controller } from 'stimulus';

const SUCCESS_NOTIFICATION_DURATION = 2000;

export default class extends Controller {
  static values = { copy: String };

  copy(event) {
    navigator.clipboard.writeText(this.copyValue).then(() => this.onCopy());
  }

  onCopy() {
    this.element.classList.add('CopyButton--success');

    setTimeout(() => {
      this.element.classList.remove('CopyButton--success');
    }, SUCCESS_NOTIFICATION_DURATION);
  }
}
