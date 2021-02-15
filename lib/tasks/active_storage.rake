# frozen_string_literal: true

desc 'Rename active storage attachments from Voice to Message::File'
task rename_active_storage_attachments: :environment do
  ActiveStorage::Attachment.where(record_type: 'Voice').update(record_type: 'Message::File')
end
