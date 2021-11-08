import { Controller } from '@hotwired/stimulus';

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
