import { Controller } from '@hotwired/stimulus';
import replacePlaceholder from '../../assets/javascript/helpers/replace-placeholder.js';

export default class extends Controller {
  static targets = ['input', 'highlights'];

  connect() {
    this.offset = this.inputTarget.offsetHeight - this.inputTarget.clientHeight;
    this.resize();
    this.highlightPlaceholders();
  }

  resize() {
    this.inputTarget.style.height = 'auto';
    this.inputTarget.style.height =
      this.inputTarget.scrollHeight + this.offset + 'px';
  }

  highlightPlaceholders() {
    const placeholder = 'VORNAME';
    if (!this.hasHighlightsTarget) {
      return;
    }

    const highlightedText = replacePlaceholder(
      this.inputTarget.value,
      placeholder,
      '<span class="Placeholder">$1</span>',
    );

    this.highlightsTarget.innerHTML = highlightedText;
  }
}
