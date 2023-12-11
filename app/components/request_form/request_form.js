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
    'characterCounter',
  ];
  static values = {
    membersCountMessage: String,
    previewFallback: String,
  };

  connect() {
    this.updatePreview();
    this.updateMembersCount();
    this.imageInputTarget.classList.add('hidden');
    this.updateCharacterCounter();
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
    const imagePreviewCaption = document.getElementById('caption');
    if (imagePreviewCaption) {
      imagePreviewCaption.innerHTML = this.setCaption();
    } else {
      this.previewTarget.innerHTML = this.setMessage();
    }

    if (event?.target?.files?.length) {
      this.previewTarget.innerHTML = '';
      this.addImagePreview(event.target.files, this.setCaption());
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

      if (
        file.type.split('/')[0] !== 'image' ||
        file.type.split('/')[1].includes('svg')
      ) {
        this.updateFilesname(i, file);
        const label = document.createElement('label');
        label.innerText =
          'Kein gültiges Bildformat. Bitte senden Sie Bilder als jpg, png oder gif.';
        label.classList.add('RequestForm-imageErrorMessage');
        this.filenamesTarget.appendChild(label);
        this.previewTarget.innerHTML = this.setMessage();
        continue;
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
      this.addImagePreview(this.imageInputTarget.files, this.setCaption());
    }
  }

  setMessage() {
    const placeholder = 'VORNAME';
    let message = sanitize(this.messageTarget.value);
    message = message || this.previewFallbackValue;
    return replacePlaceholder(message, placeholder, 'Max');
  }

  setCaption() {
    const placeholder = 'VORNAME';
    const message = sanitize(this.messageTarget.value);
    if (message && message.length > 0) {
      return replacePlaceholder(message, placeholder, 'Max');
    } else {
      return message;
    }
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

  updateCharacterCounter() {
    const characters = this.messageTarget.value.length;
    const maxLength = 1500;
    this.characterCounterTarget.innerText = `${characters} / ${maxLength} Zeichen`;
    const isInvalid = characters > maxLength;
    this.characterCounterTarget.classList.toggle(
      'CharacterCounter--invalidText',
      isInvalid
    );
    isInvalid
      ? this.submitButtonTarget.setAttribute('disabled', isInvalid)
      : this.submitButtonTarget.removeAttribute('disabled');
  }
}
