import { Controller } from 'stimulus';

export default class extends Controller {
  setDirty() {
    this.element.classList.add('UserProfile--dirty');
  }

  resetDirty() {
    this.element.classList.remove('UserProfile--dirty');
  }
}
