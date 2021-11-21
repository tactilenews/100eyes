import { Controller } from '@hotwired/stimulus';
import Tagify from '@yaireo/tagify';

const tagColor = tagData => {
  return tagData.color ? tagData.color : 'var(--color-text)';
};

function dropdownItemTemplate(tagData) {
  const { one, other } = this.settings.labels.members;
  const membersLabel = tagData.count === 1 ? one : other;
  const color = tagColor(tagData);

  return `
    <div ${this.getAttributes(tagData)}
      class="${this.settings.classNames.dropdownItem} TagsInput-dropdownItem"
      tabindex="0"
      role="option"
    >
      <span class="tagify__tag" style="--tag-color: ${color}">
        <div>
          <span class="tagify__tag-text">${tagData.name}</span>
        </div>
      </span>
      <span class="TagsInput-count">${tagData.count} ${membersLabel}<span>
    </div>
  `;
}

function transformTag(tagData) {
  const color = tagColor(tagData);

  tagData.style = `--tag-color: ${color}`;
}

export default class extends Controller {
  static targets = ['input'];
  static values = {
    availableTags: String,
    allowNew: Boolean,
    membersLabel: String,
  };

  connect() {
    this.tagify = new Tagify(this.inputTarget, {
      originalInputValueFormat: tags => {
        return tags.map(tag => tag.value).join(',');
      },

      whitelist: JSON.parse(this.availableTagsValue),
      enforceWhitelist: !this.allowNewValue,
      editTags: false,

      dropdown: {
        classname: 'TagsInput-dropdown',
        enabled: 0,
        closeOnSelect: false,
        placeAbove: false,
        maxItems: 100,
      },

      templates: {
        dropdownItem: dropdownItemTemplate,
      },

      transformTag,
      labels: {
        members: JSON.parse(this.membersLabelValue),
      },
    });

    this.tagify.on('add', () => this.fireInputEvent());
    this.tagify.on('remove', () => this.fireInputEvent());
  }

  disconnect() {
    this.tagify.destroy();
  }

  fireInputEvent() {
    const event = new CustomEvent('changeTags', {
      bubbles: true,
      cancelable: true,
      detail: {
        tags: this.tagify.value.map(({ value }) => value),
      },
    });

    this.element.dispatchEvent(event);
  }
}
