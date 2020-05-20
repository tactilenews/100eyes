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
  message = sanitize(message) || '<span class="Placeholder">Frage</span>';

  notes = Object.entries(notes)
    .filter(([key, isActive]) => isActive)
    .map(([key]) => NOTE_TEXTS[key]);

  const intro = 'Hallo, die Redaktion hat eine neue Frage an dich:';
  const outro = 'Vielen Dank für deine Hilfe bei unserer Recherche!';

  return [ intro, message, ...notes, outro ].join('\n\n');
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
