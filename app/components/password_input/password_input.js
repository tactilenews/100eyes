import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['input', 'toggle'];
  static values = {
    unmask: String,
    mask: String,
  };

  toggle() {
    this.inputTarget.type =
      this.inputTarget.type === 'password' ? 'text' : 'password';

    this.toggleTarget.innerHTML =
      this.inputTarget.type === 'password' ? this.unmaskValue : this.maskValue;
  }
}
