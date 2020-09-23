import { Controller } from 'stimulus';
import Tagify from '@yaireo/tagify';

function dropdownItemTemplate(tagData) {
  return `
    <div ${this.getAttributes(tagData)}
      class="${this.settings.classNames.dropdownItem} TagsInput-dropdownItem"
      tabindex="0"
      role="option"
    >
      <span class="TagsInput-name">${tagData.name}</span>
      <span class="TagsInput-count">${tagData.count} Mitglieder<span>
    </div>
  `;
}

export default class extends Controller {
  static targets = ['input'];

  connect() {
    new Tagify(this.inputTarget, {
      originalInputValueFormat: tags => tags.map(tag => tag.value).join(','),
      whitelist: JSON.parse(this.data.get('available-tags')),
      enforceWhitelist: !JSON.parse(this.data.get('allow-new')),
      dropdown: {
        classname: 'TagsInput-dropdown',
        enabled: 0,
        closeOnSelect: false,
      },
      templates: {
        dropdownItem: dropdownItemTemplate,
      },
    });
  }
}
