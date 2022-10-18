# frozen_string_literal: true

class ThreemaValidator < ActiveModel::Validator
  def validate(record)
    return if Threema::Lookup.new(threema: Threema.new).key(record.threema_id.upcase)

    record.errors.add :threema_id, I18n.t('contributor.form.threema_id.invalid')
  end
end
