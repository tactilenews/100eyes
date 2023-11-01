# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_10_24_144124) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_notifications", force: :cascade do |t|
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.string "type", null: false
    t.jsonb "params"
    t.datetime "read_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "contributor_id"
    t.bigint "message_id"
    t.bigint "request_id"
    t.bigint "user_id"
    t.index ["contributor_id"], name: "index_activity_notifications_on_contributor_id"
    t.index ["message_id"], name: "index_activity_notifications_on_message_id"
    t.index ["read_at"], name: "index_activity_notifications_on_read_at"
    t.index ["recipient_type", "recipient_id"], name: "index_activity_notifications_on_recipient"
    t.index ["request_id"], name: "index_activity_notifications_on_request_id"
    t.index ["user_id"], name: "index_activity_notifications_on_user_id"
  end

  create_table "business_plans", force: :cascade do |t|
    t.string "name"
    t.integer "price_per_month"
    t.integer "setup_cost"
    t.integer "hours_of_included_support"
    t.integer "number_of_users"
    t.integer "number_of_contributors"
    t.integer "number_of_communities"
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_business_plans_on_name", unique: true
  end

  create_table "contributors", force: :cascade do |t|
    t.string "email"
    t.bigint "telegram_chat_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "username"
    t.string "first_name"
    t.string "last_name"
    t.bigint "telegram_id"
    t.string "note"
    t.string "zip_code"
    t.string "city"
    t.string "phone"
    t.datetime "deactivated_at"
    t.string "threema_id"
    t.datetime "data_processing_consented_at"
    t.string "telegram_onboarding_token"
    t.string "signal_phone_number"
    t.datetime "signal_onboarding_completed_at"
    t.string "additional_email"
    t.datetime "additional_consent_given_at"
    t.bigint "organization_id"
    t.string "whats_app_phone_number"
    t.datetime "whats_app_message_template_responded_at"
    t.bigint "deactivated_by_user_id"
    t.boolean "deactivated_by_admin", default: false
    t.datetime "whats_app_message_template_sent_at"
    t.string "external_id"
    t.string "external_channel"
    t.index ["email"], name: "index_contributors_on_email", unique: true
    t.index ["organization_id"], name: "index_contributors_on_organization_id"
    t.index ["signal_phone_number"], name: "index_contributors_on_signal_phone_number", unique: true
    t.index ["telegram_chat_id"], name: "index_contributors_on_telegram_chat_id", unique: true
    t.index ["telegram_id"], name: "index_contributors_on_telegram_id", unique: true
    t.index ["threema_id"], name: "index_contributors_on_threema_id", unique: true
    t.index ["whats_app_phone_number"], name: "index_contributors_on_whats_app_phone_number", unique: true
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "json_web_tokens", force: :cascade do |t|
    t.string "invalidated_jwt"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "contributor_id"
    t.index ["contributor_id"], name: "index_json_web_tokens_on_contributor_id"
  end

  create_table "message_files", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["message_id"], name: "index_message_files_on_message_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "sender_id"
    t.bigint "request_id", null: false
    t.string "text"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "telegram_media_group_id"
    t.integer "photos_count"
    t.bigint "recipient_id"
    t.boolean "broadcasted", default: false
    t.boolean "unknown_content", default: false
    t.boolean "blocked", default: false
    t.boolean "highlighted", default: false
    t.bigint "creator_id"
    t.string "sender_type"
    t.datetime "received_at"
    t.datetime "read_at"
    t.index ["creator_id"], name: "index_messages_on_creator_id"
    t.index ["recipient_id"], name: "index_messages_on_recipient_id"
    t.index ["request_id"], name: "index_messages_on_request_id"
    t.index ["sender_id", "sender_type"], name: "index_messages_on_sender_id_and_sender_type"
    t.index ["telegram_media_group_id"], name: "index_messages_on_telegram_media_group_id", unique: true
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.integer "upgrade_discount"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "business_plan_id", null: false
    t.bigint "contact_person_id"
    t.datetime "upgraded_business_plan_at"
    t.index ["business_plan_id"], name: "index_organizations_on_business_plan_id"
    t.index ["contact_person_id"], name: "index_organizations_on_contact_person_id"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "photos", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["message_id"], name: "index_photos_on_message_id"
  end

  create_table "requests", force: :cascade do |t|
    t.string "title"
    t.string "text"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "replies_count"
    t.bigint "user_id"
    t.datetime "schedule_send_for"
    t.datetime "broadcasted_at"
    t.index ["user_id"], name: "index_requests_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "email", null: false
    t.string "encrypted_password", limit: 128, null: false
    t.string "confirmation_token", limit: 128
    t.string "remember_token", limit: 128, null: false
    t.string "otp_secret_key"
    t.boolean "otp_enabled", default: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "admin", default: false
    t.bigint "organization_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["remember_token"], name: "index_users_on_remember_token"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_notifications", "contributors"
  add_foreign_key "activity_notifications", "messages"
  add_foreign_key "activity_notifications", "requests"
  add_foreign_key "activity_notifications", "users"
  add_foreign_key "contributors", "organizations"
  add_foreign_key "json_web_tokens", "contributors"
  add_foreign_key "message_files", "messages"
  add_foreign_key "messages", "contributors", column: "recipient_id"
  add_foreign_key "messages", "requests"
  add_foreign_key "organizations", "business_plans"
  add_foreign_key "organizations", "users", column: "contact_person_id"
  add_foreign_key "photos", "messages"
  add_foreign_key "requests", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "users", "organizations"
end
