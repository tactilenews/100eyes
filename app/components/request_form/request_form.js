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
    'modal',
    'imageInputAttachedFile',
  ];
  static values = {
    membersCountMessage: String,
    previewFallback: String,
    requestFilesUrl: Array,
    updateMembersCountUrl: String,
  };

  connect() {
    this.updatePreview();
    this.updateMembersCount();
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

    if (event?.target?.files?.length || this.requestFilesUrlValue.length) {
      this.previewTarget.innerHTML = '';
      this.messageTarget.removeAttribute('required');
    }
    if (event?.target?.files?.length)
      this.addImagePreview(event.target.files, this.setCaption());
    if (this.requestFilesUrlValue.length) {
      this.filenamesTarget.parentNode.classList.remove(
        'RequestForm-filenamesWrapper--hidden',
      );
      this.addAttachedRequestFilesPreview(
        this.requestFilesUrlValue,
        this.setCaption(),
      );
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
      url: this.updateMembersCountUrlValue,
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

  setUpImagePreview() {
    let figure = document.getElementById('file-preview');
    let div;
    if (figure) {
      div = document.getElementById('image-preview-wrapper');
    } else {
      figure = document.createElement('figure');
      div = document.createElement('div');
      div.classList.add('RequestForm-imagePreviewWrapper');
      div.setAttribute('id', 'image-preview-wrapper');
    }

    figure.appendChild(div);
    this.previewTarget.parentNode.appendChild(figure);

    return [figure, div];
  }

  addImagePreview(files, message) {
    const [figure, div] = this.setUpImagePreview();

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
      this.setImageAttributes(img, URL.createObjectURL(file));
    }

    this.addPreview(figure, message);
  }

  addAttachedRequestFilesPreview(urls, message) {
    const [figure, div] = this.setUpImagePreview();

    urls.forEach((url, i) => {
      const existingImage = document.getElementById(`image-${url}`);
      if (!existingImage) {
        const img = document.createElement('img');
        img.setAttribute('id', `image-${url}`);
        img.classList.add('RequestForm-imagePreview');
        if (urls.length % 2 == 1 && i == 0) {
          img.classList.add('RequestForm-firstImageInOddNumber');
        }
        div.appendChild(img);
        this.setImageAttributes(img, url);
      }
    });

    this.addPreview(figure, message);
  }

  addPreview(figure, message) {
    let figcaption = document.getElementById('caption');

    if (!figcaption) {
      figcaption = document.createElement('figcaption');
      figcaption.setAttribute('id', 'caption');
      figure.setAttribute('id', 'file-preview');
      figure.appendChild(figcaption);
    }

    figure.appendChild(figcaption);
    figcaption.innerHTML = message;
  }

  removeExistingImagePreview() {
    const existingFigure = document.getElementById('file-preview');
    if (existingFigure) existingFigure.remove();
    const chatPreviewBubbles = document.querySelectorAll(
      '.ChatPreview-bubble--preview',
    );
    chatPreviewBubbles.forEach((element, index) => {
      if (index > 0) {
        element.remove();
      }
    });
  }

  removeExistingFilesname() {
    const listItems = document.querySelectorAll(
      '.RequestForm-filenamesListItem',
    );
    listItems.forEach(listItem => listItem.remove());
  }

  setImageAttributes(img, url) {
    img.setAttribute('src', url);
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
    this.removeExistingImagePreview();
    this.updatePreviewAfterRemoveEvent();
  }

  removeAttachedImage(event) {
    event.target.parentNode.remove();

    const id = event.target.dataset.requestFormImageIdValue;
    const url = event.target.dataset.requestFormImageUrlValue;
    this.requestFilesUrlValue = this.requestFilesUrlValue.filter(u => u != url);
    const hiddenInputs = this.imageInputAttachedFileTargets;
    const inputToDelete = hiddenInputs.find(
      image => image.getAttribute('value') == id,
    );
    inputToDelete.remove();
    this.removeExistingImagePreview();
    this.updatePreviewAfterRemoveEvent();
  }

  updatePreviewAfterRemoveEvent() {
    if (
      this.imageInputTarget.files.length == 0 &&
      this.imageInputAttachedFileTargets.length == 0
    ) {
      this.filenamesTarget.parentNode.classList.add(
        'RequestForm-filenamesWrapper--hidden',
      );
      this.previewTarget.innerHTML = this.setMessage();
      this.messageTarget.setAttribute('required', true);
    } else {
      this.addImagePreview(this.imageInputTarget.files, this.setCaption());
      this.addAttachedRequestFilesPreview(
        this.requestFilesUrlValue,
        this.setCaption(),
      );
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
    let listItem = document.getElementById(`image-filename-${file.name}`);

    if (!listItem) {
      listItem = document.createElement('li');
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
        'RequestForm-filenamesWrapper--hidden',
      );
    }
  }

  updateCharacterCounter() {
    const characters = this.messageTarget.value.length;
    const maxLength = 1500;
    this.characterCounterTarget.innerText = `${characters} / ${maxLength} Zeichen`;
    const isInvalid = characters > maxLength;
    this.characterCounterTarget.classList.toggle(
      'CharacterCounter--invalidText',
      isInvalid,
    );
    isInvalid
      ? this.submitButtonTarget.setAttribute('disabled', isInvalid)
      : this.submitButtonTarget.removeAttribute('disabled');
  }

  openModal() {
    this.modalTarget.showModal();
  }

  closeModal() {
    this.modalTarget.close();
  }
}
