import { Controller } from '@hotwired/stimulus';

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
    if (!this.hasHighlightsTarget) {
      return;
    }

    const highlightedText = this.inputTarget.value.replace(
      /({{\s*FIRST_NAME\s*}})/gi,
      '<span class="Textarea-placeholder">$1</span>'
    );

    this.highlightsTarget.innerHTML = highlightedText;
  }
}
