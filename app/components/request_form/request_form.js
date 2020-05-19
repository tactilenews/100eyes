import { Controller } from 'stimulus';
import sanitize from '../../../frontend/helpers/sanitize.js';

const NOTE_TEXTS = {
  photo: 'Textbaustein für Fotonutzung',
  address: 'Textbaustein für Addressnutzung',
  contact: 'Textbaustein für Kontaktweitergabe',
  medicalInfo: 'Textbaustein für medizinische Informationen',
  confidential: 'Textbaustein für vertrauliche Informationen',
};

const template = ({ message, notes }) => {
  message =
    sanitize(message).replace(/\n/g, '<br>') ||
    '<span class="Placeholder">Frage</span>';

  notes = Object.entries(notes)
    .filter(([key, isActive]) => isActive)
    .map(([key]) => NOTE_TEXTS[key]);

  return `
        <p>Hallo, die Redaktion hat eine neue Frage an dich:</p>
        <p>${message}</p>
        ${notes.map(note => `<p>${note}</p>`).join('')}
        <p>Vielen Dank für deine Hilfe bei unserer Recherche!</p>
    `;
};

export default class extends Controller {
  static targets = [
    'preview',
    'message',
    'photo',
    'address',
    'contact',
    'medicalInfo',
    'confidential',
  ];

  connect() {
    this.updatePreview();
  }

  updatePreview() {
    const data = {
      message: this.messageTarget.value,
      notes: {
        photo: this.photoTarget.checked,
        address: this.addressTarget.checked,
        contact: this.contactTarget.checked,
        medicalInfo: this.medicalInfoTarget.checked,
        confidential: this.confidentialTarget.checked,
      },
    };

    this.previewTarget.innerHTML = template(data);
  }
}
