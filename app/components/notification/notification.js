import { Controller } from 'stimulus';

export default class extends Controller {
  static values = {
    showAlways: Boolean,
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
  }

  close() {
    this.element.remove();
  }
}
