import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [
    'filename',
    'thumbnail',
    'link',
    'selectedImage',
    'emptyState',
  ];

  connect() {
    const files = this.element.querySelector('input').files;

    if (files.length <= 0) {
      return;
    }

    this.updateFilePreview(files[0]);
  }

  selectFile(event) {
    this.updateFilePreview(event.target.files[0]);
  }

  updateFilePreview(file) {
    const url = URL.createObjectURL(file);

    this.filenameTarget.innerText = file.name;
    this.thumbnailTarget.src = url;
    this.linkTarget.href = url;

    this.emptyStateTarget.hidden = true;
    this.selectedImageTarget.hidden = false;
  }
}
