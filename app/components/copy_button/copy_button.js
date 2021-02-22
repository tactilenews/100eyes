import { Controller } from 'stimulus';

const SUCCESS_NOTIFICATION_DURATION = 2000;

export default class extends Controller {
  static values = { copy: String };
  static classes = ['success'];

  copy(event) {
    navigator.clipboard.writeText(this.copyValue).then(() => this.onCopy());
  }

  onCopy() {
    this.element.classList.add(this.successClass);

    setTimeout(() => {
      this.element.classList.remove(this.successClass);
    }, SUCCESS_NOTIFICATION_DURATION);
  }
}
