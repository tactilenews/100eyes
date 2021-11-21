import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    showAlways: Boolean,
    closeAfter: Number,
  };

  connect() {
    document.addEventListener('turbo:before-cache', () => {
      // Prevent flickering of notifications that are always
      // displayed, i.e. across page navigations
      if (this.showAlwaysValue) {
        return;
      }

      this.close();
    });

    if (this.closeAfterValue) {
      window.setTimeout(() => this.close(), this.closeAfterValue);
    }
  }

  close() {
    this.element.classList.add('Notification--closed');
  }
}
