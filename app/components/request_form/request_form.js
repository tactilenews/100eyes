import { Controller } from 'stimulus';
import sanitize from '../../../frontend/helpers/sanitize.js';

const HINT_TEXTS = {
  photo:
    'Schicken Sie uns doch auch ein Foto (oder mehrere). Bitte schicken Sie nur Fotos, die Sie selber gemacht haben. Mit der Zusendung von Fotos geben Sie gleichzeitig Ihr Einverständnis für eine mögliche Veröffentlichung. Bei Veröffentlichung nennen wir Sie als Urheber (Foto: Max Mustermann/100eyes).',
  address:
    'Schicken Sie uns doch eine Adresse oder genaue Koordinaten. Wir nutzen die Geodaten für unsere Recherchen und werden sie eventuell in einem Text verarbeiten oder als Datenpunkt auf einer Karte verwenden.',
  contact:
    'Schicken Sie uns gerne Kontaktdaten. Wir nutzen die Kontaktdaten für unsere Recherchen und werden die Person eventuell kontaktieren, aber keine Kontaktdaten veröffentlichen.',
  medicalInfo:
    'Sie stellen uns hier möglicherweise sensible medizinische Informationen bereit. Wir sind uns dessen bewusst und behandeln Ihre Daten mit aller gebotenen Vorsicht. Wenn Sie uns Daten schicken, helfen uns diese Informationen für unsere weiteren Recherchen. Ihre Daten werden wir nur intern auswerten, aber nicht veröffentlichen. Es sei denn, Sie geben Ihr ausdrückliches Einverständnis, nachdem wir Sie separat darum gebeten haben.',
  confidential:
    'Sie stellen uns hier möglicherweise vertrauliche Informationen bereit. Wir sind uns dessen bewusst und behandeln diese Informationen mit aller gebotenen Vorsicht. Wir werden Ihre Informationen nur intern auswerten, aber nicht ungefragt veröffentlichen.',
};

const template = ({ message, notes }) => {
  message = sanitize(message) || '<span class="Placeholder">Frage</span>';

  notes = Object.entries(notes)
    .filter(([key, isActive]) => isActive)
    .map(([key]) => HINT_TEXTS[key]);

  const intro = 'Hallo, die Redaktion hat eine neue Frage an Sie:';
  const outro = 'Vielen Dank für Ihre Hilfe bei unserer Recherche!';

  return [intro, message, ...notes, outro].join('\n\n');
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
