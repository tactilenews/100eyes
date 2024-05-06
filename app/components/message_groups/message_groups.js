import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    document.addEventListener('turbo:frame-render', event => {
      const anchor = new URL(document.location).hash;
      if (!anchor) return;

      const turboFrame = event.target;
      const elementToScrollTo = turboFrame.querySelector(anchor);
      if (!elementToScrollTo) return;

      elementToScrollTo.scrollIntoView({ behavior: 'smooth', block: 'center' });
      Object.assign(elementToScrollTo.style, {
        borderColor: '#007eff',
        boxShadow: '0 0 0 3px #7ac8ff',
      });
    });
  }
}
