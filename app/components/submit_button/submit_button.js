import { Controller } from 'stimulus';

export default class extends Controller {
  setLoadingState() {
    this.element.classList.add('Button--loading');
    setTimeout(() => (this.element.disabled = true), 0);
  }

  resetLoadingState() {
    this.element.classList.remove('Button--loading');
    this.element.disabled = false;
  }
}
