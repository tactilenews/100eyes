# frozen_string_literal: true

class ThreemaValidator < ActiveModel::Validator
  def validate(record)
    return if threema_id_valid(record)

    record.errors.add :threema_id, I18n.t('contributor.form.threema_id.invalid')
  end

  private

  def threema_id_valid(record)
    record.threema_id.match?(/\A[A-Za-z0-9]+\z/) &&
      record.threema_id.length.eql?(8) &&
      Threema::Lookup.new(threema: record.organization.threema_instance).key(record.threema_id.upcase).present?
  end
end
