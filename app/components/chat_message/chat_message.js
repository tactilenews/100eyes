import { Controller } from '@hotwired/stimulus';
import Rails from '@rails/ujs';

export default class extends Controller {
  static targets = ['copyButton', 'text', 'toggleExpanded'];
  static classes = ['truncated', 'expanded', 'highlighted'];

  static values = {
    senderName: String,
    id: String,
    copyUrl: String,
    highlightUrl: String,
  };

  connect() {
    if (this.isTruncated()) {
      this.element.classList.add(this.truncatedClass);
      this.collapse();
    }

    if (this.hasTextTarget) {
      this.setCopyValue();
    } else {
      this.setCopyUrlValue();
    }
  }

  isTruncated() {
    if (this.hasTextTarget) {
      return (
        this.textTarget.parentNode.clientHeight <
        this.textTarget.parentNode.scrollHeight
      );
    }
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

  setCopyValue() {
    if (!this.hasCopyButtonTarget) return;

    const text = this.textTarget.innerText;

    const sender = this.senderNameValue;
    let copyValue = `${sender}: ${text}`;

    if (!sender) {
      copyValue = text;
    }

    this.copyButtonTarget.dataset.copyButtonCopyValue = copyValue;
  }

  setCopyUrlValue() {
    if (!this.hasCopyButtonTarget) return;

    this.copyButtonTarget.dataset.copyButtonCopyValue = this.copyUrlValue;
  }

  isHighlighted() {
    return this.element.classList.contains(this.highlightedClass);
  }

  toggleHighlighted() {
    Rails.ajax({
      url: this.highlightUrlValue,
      type: 'PATCH',
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
