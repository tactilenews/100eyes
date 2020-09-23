import { Controller } from 'stimulus';
import Tagify from '@yaireo/tagify';

const COLORS = ['#F4C317', '#0898FF', '#67D881', '#F4177A'];

function dropdownItemTemplate(tagData) {
  const membersLabel = tagData.count === 1 ?
    this.settings.labels.members.one :
    this.settings.labels.members.other;

  return `
    <div ${this.getAttributes(tagData)}
      class="${this.settings.classNames.dropdownItem} TagsInput-dropdownItem"
      tabindex="0"
      role="option"
    >
      <span class="TagsInput-name">${tagData.name}</span>
      <span class="TagsInput-count">${tagData.count} ${membersLabel}<span>
    </div>
  `;
}

function transformTag(tagData) {
  const COLORS = ['#F4C317', '#0898FF', '#67D881', '#F4177A'];
  const tagColor = COLORS[tagData.id % COLORS.length];

  tagData.style = `
    --tag-bg: ${tagColor};
    --tag-hover: ${tagColor};
  `;
}

export default class extends Controller {
  static targets = ['input'];

  connect() {
    new Tagify(this.inputTarget, {
      originalInputValueFormat: tags => {
        tags.map(tag => tag.value).join(',')
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
  }
}
