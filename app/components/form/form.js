import { Controller } from 'stimulus';

export default class extends Controller {
  static values = {
    autoSubmit: Boolean,
  };

  disableSubmit() {
    const submit = this.element.querySelector('.Button[type="submit"]');
    submit.disabled = true;
    submit.classList.add('Button--loading');
  }

  autoSubmit() {
    if (!this.autoSubmitValue) {
      return;
    }

    this.element.submit();
  }
}
