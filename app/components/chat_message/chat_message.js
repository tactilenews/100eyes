import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

const SUCCESS_NOTIFICATION_DURATION = 2000;

export default class extends Controller {
  static targets = ['text', 'toggleExpanded'];
  static values = {
    senderName: String,
    id: String,
  };

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

  toggleExpanded() {
    if (this.isExpanded()) {
      this.collapse();
    } else {
      this.expand();
    }
  }

  expand() {
    this.element.classList.add('ChatMessage--expanded');
    this.toggleExpandedTarget.setAttribute('aria-expanded', 'true');
  }

  collapse() {
    this.element.classList.remove('ChatMessage--expanded');
    this.toggleExpandedTarget.setAttribute('aria-expanded', 'false');
  }

  copy() {
    const text = this.textTarget.innerText;
    const sender = this.senderNameValue;
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
    }, SUCCESS_NOTIFICATION_DURATION);
  }

  isHighlighted() {
    return this.element.classList.contains('ChatMessage--highlighted');
  }

  toggleHighlighted() {
    Rails.ajax({
      url: `/messages/${this.idValue}/highlight`,
      type: 'POST',
      data: `highlighted=${!this.isHighlighted()}`,
    });

    if (this.isHighlighted()) {
      this.unhighlight();
    } else {
      this.highlight();
    }
  }

  highlight() {
    this.element.classList.add('ChatMessage--highlighted');
  }

  unhighlight() {
    this.element.classList.remove('ChatMessage--highlighted');
  }
}
