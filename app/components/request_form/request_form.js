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
    'filenames',
    'submitButton',
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
    const message = this.setMessage();
    const imagePreviewCaption = document.getElementById('caption');
    if (imagePreviewCaption) {
      imagePreviewCaption.innerHTML = message;
    } else {
      this.previewTarget.innerHTML = message;
    }

    if (event?.target?.files?.length) {
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
    const div = document.createElement('div');
    div.classList.add('RequestForm-imagePreviewWrapper');
    this.removeExistingPreview();

    for (let i = 0; i < files.length; i++) {
      let file = files.item(i);

      if (file.type.split('/')[0] !== 'image') {
        this.updateFilesname(i, file);
        const label = document.createElement('label');
        label.innerText =
          'Kein gültiges Bildformat. Bitte senden Sie Bilder als jpg, png oder gif.';
        label.classList.add('RequestForm-imageErrorMessage');
        this.filenamesTarget.appendChild(label);
        this.previewTarget.innerHTML = this.setMessage();
        return;
      }
      const img = document.createElement('img');
      img.classList.add('RequestForm-imagePreview');
      this.updateFilesname(i, file);
      if (files.length % 2 == 1 && i == 0) {
        img.classList.add('RequestForm-firstImageInOddNumber');
      }
      div.appendChild(img);
      this.setImageAttributes(img, file);
    }
    figure.appendChild(div);
    const figcaption = document.createElement('figcaption');
    figcaption.setAttribute('id', 'caption');
    figure.setAttribute('id', 'file-preview');
    figure.appendChild(figcaption);

    this.previewTarget.parentNode.appendChild(figure);
    const firstFigcaption = figure.querySelector('figcaption');
    firstFigcaption.innerHTML = message;
  }

  removeExistingPreview() {
    const existingFigure = document.getElementById('file-preview');
    if (existingFigure) existingFigure.remove();
    const chatPreviewBubbles = document.querySelectorAll(
      '.ChatPreview-bubble--preview'
    );
    chatPreviewBubbles.forEach((element, index) => {
      if (index > 0) {
        element.remove();
      }
    });
    const listItems = document.querySelectorAll(
      '.RequestForm-filenamesListItem'
    );
    listItems.forEach(listItem => listItem.remove());
  }

  setImageAttributes(img, file) {
    img.setAttribute('src', URL.createObjectURL(file));
    img.setAttribute('width', 100);
    img.setAttribute('width', 100);
  }

  removeImage(event) {
    const index = Number(event.target.dataset.requestFormImageIndexValue);
    const dt = new DataTransfer();
    const { files } = this.imageInputTarget;

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      if (index !== i) dt.items.add(file);
    }

    this.imageInputTarget.files = dt.files;
    event.target.parentNode.remove();
    if (this.imageInputTarget.files.length == 0) {
      this.removeExistingPreview();
      this.filenamesTarget.parentNode.classList.add(
        'RequestForm-filenamesWrapper--hidden'
      );
      this.previewTarget.innerHTML = this.setMessage();
    } else {
      this.addImagePreview(this.imageInputTarget.files, this.setMessage());
    }
  }

  setMessage() {
    const placeholder = 'VORNAME';
    let message = sanitize(this.messageTarget.value);
    message = message || this.previewFallbackValue;
    return replacePlaceholder(message, placeholder, 'Max');
  }

  updateFilesname(index, file) {
    const listItem = document.createElement('li');
    listItem.setAttribute('id', `image-filename-${file.name}`);
    listItem.classList.add('RequestForm-filenamesListItem');

    const paragraph = document.createElement('p');
    paragraph.innerText = file.name;
    paragraph.classList.add('RequestForm-filename');
    listItem.appendChild(paragraph);

    const removeButton = document.createElement('button');
    removeButton.innerText = 'x';
    removeButton.setAttribute('data-action', 'request-form#removeImage');
    removeButton.setAttribute('data-request-form-image-index-value', index);
    removeButton.setAttribute('type', 'button');
    removeButton.classList.add('Button');
    removeButton.classList.add('RequestForm-removeListItemButton');
    listItem.appendChild(removeButton);

    this.filenamesTarget.appendChild(listItem);
    this.filenamesTarget.parentNode.classList.remove(
      'RequestForm-filenamesWrapper--hidden'
    );
  }
}
