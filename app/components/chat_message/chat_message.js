import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['text', 'toggle', 'copy'];

  connect() {
    if (this.isTruncated()) {
      this.element.classList.add('ChatMessage--truncated');
      this.collapse();
    }
  }

  isTruncated() {
    return this.textTarget.clientHeight < this.textTarget.scrollHeight;
  }

  isExpanded() {
    return this.element.classList.contains('ChatMessage--expanded');
  }

  toggle() {
    if (this.isExpanded()) {
      this.collapse();
    } else {
      this.expand();
    }
  }

  expand() {
    this.element.classList.add('ChatMessage--expanded');
    this.toggleTarget.setAttribute('aria-expanded', 'true');
  }

  collapse() {
    this.element.classList.remove('ChatMessage--expanded');
    this.toggleTarget.setAttribute('aria-expanded', 'false');
  }

  copy() {
    const text = this.textTarget.innerText;
    const sender = this.data.get('sender-name');
    let clipboardText = `${sender}: ${text}`;

    if (!sender) {
      clipboardText = text;
    }

    navigator.clipboard.writeText(clipboardText).then(() => this.onCopy());
  }

  onCopy() {
    this.element.classList.add('ChatMessage--copied');

    setTimeout(() => {
      this.element.classList.remove('ChatMessage--copied');
    }, 2000);
  }
}
