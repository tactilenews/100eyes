import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['modal'];

  connect() {
    console.log('connected', this.hasModalTarget);
  }

  openModal() {
    console.log('open me');
    this.modalTarget.showModal();
  }
}
