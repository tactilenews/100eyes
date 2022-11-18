import { Controller } from '@hotwired/stimulus';
import Rails from '@rails/ujs';
import sanitize from '../../assets/javascript/helpers/sanitize.js';
import replacePlaceholder from '../../assets/javascript/helpers/replace-placeholder.js';

export default class extends Controller {
  static targets = [
    'preview',
    'message',
    'membersCount',
    'imageInput',
    'imagePreview',
  ];
  static values = {
    membersCountMessage: String,
    previewFallback: String,
  };

  connect() {
    this.updatePreview();
    this.updateMembersCount();
    this.imageInputTarget.classList.add('hidden');
  }

  insertPlaceholderAtCursor() {
    const placeholder = '{{VORNAME}}';
    const [start, end] = [
      this.messageTarget.selectionStart,
      this.messageTarget.selectionEnd,
    ];
    this.messageTarget.setRangeText(placeholder, start, end, 'end');
    const event = new Event('input', { bubbles: true });
    this.messageTarget.dispatchEvent(event);
    this.messageTarget.focus();
  }

  updatePreview(event) {
    const placeholder = 'VORNAME';
    let message = sanitize(this.messageTarget.value);
    message = message || this.previewFallbackValue;
    message = replacePlaceholder(message, placeholder, 'Max');
    const imagePreviewCaption = document.getElementById('caption');
    if (imagePreviewCaption) {
      imagePreviewCaption.innerHTML = message;
    } else {
      this.previewTarget.innerHTML = message;
    }

    if (event && event.target.files) {
      this.previewTarget.innerHTML = '';
      this.addImagePreview(event.target.files, message);
    }
  }

  updateMembersCount(event) {
    if (!event || event.detail.tags.length <= 0) {
      this.membersCountTarget.hidden = true;
      return;
    }

    const messageTemplates = JSON.parse(this.membersCountMessageValue);
    const tags = event.detail.tags;

    Rails.ajax({
      url: '/contributors/count',
      type: 'GET',
      data: new URLSearchParams({ tag_list: tags }).toString(),
      success: ({ count }) => {
        this.membersCountTarget.hidden = false;

        if (count == 1) {
          this.membersCountTarget.innerHTML = messageTemplates.one;
          return;
        }

        const message = messageTemplates.other.replace('%{count}', count);
        this.membersCountTarget.innerHTML = message;
      },
    });
  }

  insertImage() {
    this.imageInputTarget.click();
  }

  addImagePreview(files, message) {
    const figure = document.createElement('figure');
    this.removeExistingPreview();

    for (let i = 0; i < files.length; i++) {
      let file = files.item(i);
      const img = document.createElement('img');
      if (i === 0) {
        this.addImageWithCaption(figure, img);
      } else {
        this.addAdditionalChatPreviewBubbles(img);
      }

      this.setImageAttributes(img, file);
    }

    figure.setAttribute('id', 'file-preview');
    const existingFigure = document.getElementById('file-preview');
    if (existingFigure) {
      existingFigure.replaceWith(figure);
    } else {
      this.previewTarget.parentNode.appendChild(figure);
    }
    const firstFigcaption = figure.querySelector('figcaption');
    firstFigcaption.innerHTML = message;
  }

  removeExistingPreview() {
    const chatPreviewBubbles = document.querySelectorAll(
      '.ChatPreview-bubble--preview'
    );
    chatPreviewBubbles.forEach((element, index) => {
      if (index > 0) {
        element.remove();
      }
    });
  }

  addImageWithCaption(figure, img) {
    const figcaption = document.createElement('figcaption');
    figcaption.setAttribute('id', 'caption');
    figure.appendChild(img);
    figure.appendChild(figcaption);
  }

  addAdditionalChatPreviewBubbles(img) {
    const chatPreviewBubble = document.createElement('div');
    chatPreviewBubble.classList.add('ChatPreview-bubble');
    chatPreviewBubble.classList.add('ChatPreview-bubble--preview');
    chatPreviewBubble.appendChild(img);
    this.previewTarget.parentNode.parentNode.appendChild(chatPreviewBubble);
  }

  setImageAttributes(img, file) {
    img.setAttribute('src', URL.createObjectURL(file));
    img.setAttribute('width', 100);
    img.setAttribute('width', 100);
  }
}
