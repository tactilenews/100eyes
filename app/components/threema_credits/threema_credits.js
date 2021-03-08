import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

const THREESHOLD = 100;
export default class extends Controller {
  static targets = ['creditsField'];
  static values = { low: Number };
  connect() {
    const element = this.creditsFieldTarget;
    Rails.ajax({
      type: 'GET',
      url: `/threema/credits`,
      success: ({ credits }) => {
        if (credits < THREESHOLD) this.lowValue = true;
        element.innerText = credits;
      },
    });
  }
}
