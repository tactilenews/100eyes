import { Controller } from 'stimulus';
import sanitize from '../../../frontend/helpers/sanitize.js';

const template = ({ message, notes }) => {
  message = sanitize(message) || '<span class="Placeholder">Frage</span>';

  const intro = 'Hallo, die Redaktion hat eine neue Frage an Sie:';
  const outro = 'Vielen Dank für Ihre Hilfe bei unserer Recherche!';

  return [intro, message, outro].join('\n\n');
};

export default class extends Controller {
  static targets = ['preview', 'message'];

  connect() {
    this.updatePreview();
  }

  updatePreview() {
    const data = {
      message: this.messageTarget.value,
    };

    this.previewTarget.innerHTML = template(data);
  }
}
