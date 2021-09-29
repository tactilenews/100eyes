import { Controller } from 'stimulus';

export default class extends Controller {
  static values = {
    autoSubmit: Boolean,
  };

  autoSubmit() {
    if (!this.autoSubmitValue) {
      return;
    }

    this.element.submit();
  }
}
