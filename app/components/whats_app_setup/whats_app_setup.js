import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    permissionsUrl: String,
  };

  openModal() {
    const windowFeatures =
      'toolbar=no, menubar=no, width=600, height=900, top=100, left=100';
    open(
      this.permissionsUrlValue,
      'integratedOnboardingWindow',
      windowFeatures,
    );
  }
}
