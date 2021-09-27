import { Controller } from 'stimulus';

export default class extends Controller {
  connect() {
    // When Turbo renders a frame it will replace only contents that are
    // within that particular frame. In most cases, flash messages/notifications
    // are rendered outside of frames. To work around this, we hook into the
    // Turbo lifecycle and manually replace the current notifications container
    // with the one from the new response.
    this.frameRenderHandler = event =>
      this.replaceNotifications(event.detail.fetchResponse);
    window.addEventListener('turbo:frame-render', this.frameRenderHandler);
  }

  disconnect() {
    window.removeEventListener('turbo:frame-render', this.frameRenderHandler);
  }

  async replaceNotifications(fetchResponse) {
    const newDocument = document.createElement('html');
    newDocument.innerHTML = await fetchResponse.responseHTML;

    const newNotifications = newDocument.querySelector(
      '[data-controller="notifications"]'
    );

    this.element.replaceWith(newNotifications);
  }
}
