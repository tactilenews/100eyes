import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this.submitHandler = () => this.setLoadingState();
    this.element.form.addEventListener('submit', this.submitHandler);
  }

  disconnect() {
    this.element.form.removeEventListener('submit', this.submitHandler);
  }

  setLoadingState() {
    this.element.classList.add('Button--loading');
    setTimeout(() => (this.element.disabled = true), 0);
  }

  resetLoadingState() {
    this.element.classList.remove('Button--loading');
    this.element.disabled = false;
  }
}
