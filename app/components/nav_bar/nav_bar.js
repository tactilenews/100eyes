import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['navBarList'];
  static classes = ['responsive'];

  connect() {
    console.log('im here', this.hasNavBarListTarget);
  }

  toggleMenu() {
    console.log('i toggle');
    this.navBarListTarget.classList.toggle(this.responsiveClass);
  }
}
