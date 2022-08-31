import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [
    'input',
    'filename',
    'thumbnail',
    'link',
    'selectedImage',
    'emptyState',
  ];

  connect() {
    const files = this.element.querySelector('input').files;

    if (files.length > 0) {
      this.updateFilePreview(files[0]);
    }
  }

  showFilePicker() {
    this.inputTarget.click();
  }

  handleChange(event) {
    this.updateFilePreview(event.target.files[0]);
    this.element.focus();
  }

  dropFile(event) {
    event.preventDefault();

    if (event.dataTransfer.files.length <= 0) {
      return;
    }

    const file = event.dataTransfer.files[0];

    if (!file.type.startsWith('image/')) {
      return;
    }

    this.inputTarget.files = event.dataTransfer.files;
    this.updateFilePreview(event.dataTransfer.files[0]);
    this.element.focus();
  }

  updateFilePreview(file) {
    const url = URL.createObjectURL(file);

    this.filenameTarget.innerText = file.name;
    this.thumbnailTarget.src = url;
    this.linkTarget.href = url;

    this.emptyStateTarget.hidden = true;
    this.selectedImageTarget.hidden = false;
  }

  showDropArea(event) {
    event.preventDefault();
    this.element.classList.add('ImageInput--dragging');
  }

  hideDropArea(event) {
    event.preventDefault();
    this.element.classList.remove('ImageInput--dragging');
  }

  highlightDropArea(event) {
    event.preventDefault();
    this.element.classList.add('ImageInput--active');
  }

  unhighlightDropArea(event) {
    event.preventDefault();
    this.element.classList.remove('ImageInput--active');
  }
}
