import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['linkButton', 'nextButton'];

  highlightNext() {
    this.linkButtonTarget.classList.remove('Button--primary');
    this.linkButtonTarget.classList.add('Button--secondary');

    this.nextButtonTarget.classList.remove('Button--secondary');
    this.nextButtonTarget.classList.add('Button--primary');

    location.hash = '#next';
  }
}
