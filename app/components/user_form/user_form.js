import { Controller } from 'stimulus';

export default class extends Controller {
  setDirty() {
    this.element.classList.add('UserForm--dirty');
  }

  resetDirty() {
    this.element.classList.remove('UserForm--dirty');
  }
}
