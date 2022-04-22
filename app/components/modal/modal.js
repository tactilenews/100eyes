import { Controller } from '@hotwired/stimulus';
import polyfill from 'dialog-polyfill';

export default class extends Controller {
  connect() {
    polyfill.registerDialog(this.element);
  }
}
