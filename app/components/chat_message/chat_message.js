import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['text', 'expand'];

  connect() {
    if (this.isTruncated()) {
      this.element.classList.add('ChatMessage--truncated');
      this.expandTarget.setAttribute('aria-expanded', 'false');
    }
  }

  isTruncated() {
    return this.textTarget.clientHeight < this.textTarget.scrollHeight;
  }

  expand() {
    this.element.classList.add('ChatMessage--expanded');
    this.expandTarget.setAttribute('aria-expanded', 'true');
  }
}
