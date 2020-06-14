import { Controller } from 'stimulus';
import sanitize from '../../../frontend/helpers/sanitize.js';

const template = ({ message, notes }) => {
  message = sanitize(message) || '<span class="Placeholder">Frage</span>';
  return message;
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
