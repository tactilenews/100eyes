import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['modal'];

  openModal() {
    this.modalTarget.showModal();
  }

  closeModal() {
    console.log('im closing...');
    this.modalTarget.close();
  }
}
