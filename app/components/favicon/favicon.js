import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['favicon'];

  connect() {
    this.faviconTarget.href = `/assets/${window.Favicon.split('/').pop()}`;
  }
}
