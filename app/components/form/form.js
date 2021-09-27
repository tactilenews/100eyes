import { Controller } from 'stimulus';

export default class extends Controller {
  disableSubmit() {
    const submit = this.element.querySelector('.Button[type="submit"]');
    submit.disabled = true;
    submit.classList.add('Button--loading');
  }
}
