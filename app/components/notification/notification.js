import { Controller } from 'stimulus';

export default class extends Controller {
  connect() {
    document.addEventListener('turbo:before-cache', () => {
      this.close();
    });
  }

  close() {
    this.element.remove();
  }
}
