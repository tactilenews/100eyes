import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

const SUCCESS_NOTIFICATION_DURATION = 2000;

export default class extends Controller {
  static targets = ['text', 'toggleExpanded'];
  static classes = ['truncated', 'expanded', 'copied', 'highlighted'];
  static values = {
    senderName: String,
    id: String,
  };
  connect() {
    if (this.isTruncated()) {
      this.element.classList.add(this.truncatedClass);
      this.collapse();
    }
  }

  isTruncated() {
    return this.textTarget.clientHeight < this.textTarget.scrollHeight;
  }

  isExpanded() {
    return this.element.classList.contains(this.expandedClass);
  }

  toggleExpanded() {
    if (this.isExpanded()) {
      this.collapse();
    } else {
      this.expand();
    }
  }

  expand() {
    this.element.classList.add(this.expandedClass);
    this.toggleExpandedTarget.setAttribute('aria-expanded', 'true');
  }

  collapse() {
    this.element.classList.remove(this.expandedClass);
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
    this.element.classList.add(this.copiedClass);

    setTimeout(() => {
      this.element.classList.remove(this.copiedClass);
    }, SUCCESS_NOTIFICATION_DURATION);
  }

  isHighlighted() {
    return this.element.classList.contains(this.highlightedClass);
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
    this.element.classList.add(this.highlightedClass);
  }

  unhighlight() {
    this.element.classList.remove(this.highlightedClass);
  }
}
