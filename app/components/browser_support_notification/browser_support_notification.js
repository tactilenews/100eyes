import { Controller } from 'stimulus';

export default class extends Controller {
  connect() {
    if (this.isUnsupportedBrowser()) {
      this.element.hidden = false;
    }
  }

  isUnsupportedBrowser() {
    return (
      !navigator.userAgent.includes('Firefox') &&
      !navigator.userAgent.includes('Chrome')
    );
  }
}
