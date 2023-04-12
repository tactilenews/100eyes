import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['navBarList'];
  static classes = ['responsive'];

  toggleMenu() {
    this.navBarListTarget.classList.toggle(this.responsiveClass);
  }
}
