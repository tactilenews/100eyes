import { Controller } from '@hotwired/stimulus';

const STORAGE_KEY = 'gdpr_modal_state';

export default class extends Controller {
  connect() {
    if (!this.isDismissed()) {
      this.open();
    }
  }

  open() {
    this.element.showModal();
  }

  isDismissed() {
    return localStorage.getItem(STORAGE_KEY) === 'closed';
  }

  closePermanently() {
    localStorage.setItem(STORAGE_KEY, 'closed');
  }
}
