import { Controller } from 'stimulus';
import Choices from 'choices.js';

export default class extends Controller {

  static targets = ['input'];

  connect() {
    new Choices(this.inputTarget);
  }

}
