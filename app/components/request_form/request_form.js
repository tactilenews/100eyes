import { Controller } from 'stimulus';
import sanitize from '../../../frontend/helpers/sanitize.js';

const NOTE_TEXTS = {
    photo: 'Textbaustein für Fotonutzung',
    address: 'Textbaustein für Addressnutzung',
    contact: 'Textbaustein für Kontaktweitergabe',
    medicalInfo: 'Textbaustein für medizinische Informationen',
    confidential: 'Textbaustein für vertrauliche Informationen',
};

const template = ({name, message, notes, deadline }) => {
    name = sanitize(name) || '<span class="Placeholder">Name</span>';
    message = sanitize(message).replace(/\n/g, "<br>") || '<span class="Placeholder">Nachricht</span>';
    const noteTexts = [];

    for(const [key, isActive] of Object.entries(notes)) {
        if(!isActive) continue;
        noteTexts.push(NOTE_TEXTS[key]);
    }

    return `
        <p>Hallo ${ name }, die Redaktion hat eine neue Frage an dich!</p>
        <p>${ message }</p>
        ${ noteTexts.map(text => `<p>${ text }</p>`).join('') }
        <p>Vielen Dank für deine Hilfe bei unserer Recherche!</p>
    `;
};

export default class extends Controller {

    static targets = [
        'preview',
        'message',
        'photo', 'address', 'contact', 'medicalInfo', 'confidential',
        'deadline'
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
            deadline: this.deadlineTarget.value,
        };

        this.previewTarget.innerHTML = template(data);
    }
}
