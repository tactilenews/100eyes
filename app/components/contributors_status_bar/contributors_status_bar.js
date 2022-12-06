import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { contributorsStatus: String };
  static targets = ['statusBar'];

  connect() {
    this.setStatusBarWidth();
    console.log('contributorsStatus', this.hasContributorsStatusValue);
  }

  setStatusBarWidth() {
    const width = new Intl.NumberFormat('default', {
      style: 'percent',
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    }).format(this.contributorsStatusValue);
    this.statusBarTarget.style.width = width;
  }
}
