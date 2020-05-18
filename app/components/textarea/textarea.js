import { Controller } from 'stimulus';

export default class extends Controller {
  connect() {
    this.offset = this.element.offsetHeight - this.element.clientHeight;
  }

  resize() {
    this.element.style.height = 'auto';
    this.element.style.height =
      this.element.scrollHeight + this.offset + 'px';
  }
}
