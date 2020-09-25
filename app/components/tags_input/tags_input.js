import { Controller } from 'stimulus';
import Tagify from '@yaireo/tagify';

const COLORS = ['#F4C317', '#0898FF', '#67D881', '#F4177A'];

const tagColor = tagData => {
  if (!tagData.id) {
    return 'var(--color-text)';
  }

  const COLORS = ['#F4C317', '#0898FF', '#67D881', '#F4177A'];
  return COLORS[tagData.id % COLORS.length];
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
      <span class="TagsInput-name" style="--tag-bg: ${color}">
        ${tagData.name}
      </span>
      <span class="TagsInput-count">${tagData.count} ${membersLabel}<span>
    </div>
  `;
}

function transformTag(tagData) {
  const color = tagColor(tagData);

  tagData.style = `
    --tag-bg: ${color};
    --tag-hover: ${color};
    --tag-remove-bg: ${color};
    --tag-remove-btn-bg--hover: ${color};
  `;
}

export default class extends Controller {
  static targets = ['input'];

  connect() {
    this.tagify = new Tagify(this.inputTarget, {
      originalInputValueFormat: tags => {
        return tags.map(tag => tag.value).join(',');
      },

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

      transformTag,

      labels: {
        members: JSON.parse(this.data.get('members-label')),
      },
    });

    this.tagify.on('add', () => this.fireInputEvent());
    this.tagify.on('remove', () => this.fireInputEvent());
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
