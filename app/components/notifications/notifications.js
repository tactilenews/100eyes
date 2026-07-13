import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  // When Turbo renders a frame it will replace only contents that are
  // within that particular frame. In most cases, flash messages/notifications
  // are rendered outside of frames. To work around this, we hook into the
  // Turbo lifecycle and manually replace the current notifications container
  // with the one from the new response.
  async replaceNotifications(event) {
    const newDocument = document.createElement('html');
    newDocument.innerHTML = await event.detail.fetchResponse.responseHTML;

    const newNotifications = newDocument.querySelector(
      '[data-controller="notifications"]',
    );

    // Only replace if the new response includes a notifications container.
    // Turbo Frame responses that render without a layout (e.g. sidebar) do not
    // carry a notifications container, so we leave the existing flash messages
    // in place rather than removing them.
    if (newNotifications) {
      this.element.replaceWith(newNotifications);
    }
  }
}
