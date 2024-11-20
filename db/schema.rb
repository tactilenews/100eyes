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

ActiveRecord::Schema.define(version: 2024_11_20_182931) do

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
    t.bigint "organization_id"
    t.index ["contributor_id"], name: "index_activity_notifications_on_contributor_id"
    t.index ["message_id"], name: "index_activity_notifications_on_message_id"
    t.index ["organization_id"], name: "index_activity_notifications_on_organization_id"
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
    t.datetime "unsubscribed_at"
    t.string "signal_uuid"
    t.string "signal_onboarding_token"
    t.index ["organization_id", "email"], name: "idx_org_email", unique: true
    t.index ["organization_id", "signal_phone_number"], name: "idx_org_signal_phone_number", unique: true
    t.index ["organization_id", "telegram_id"], name: "idx_org_telegram_id", unique: true
    t.index ["organization_id", "threema_id"], name: "idx_org_threema_id", unique: true
    t.index ["organization_id", "whats_app_phone_number"], name: "idx_org_whats_app_phone_number", unique: true
    t.index ["organization_id"], name: "index_contributors_on_organization_id"
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
    t.integer "photos_count", default: 0
    t.bigint "recipient_id"
    t.boolean "broadcasted", default: false
    t.boolean "unknown_content", default: false
    t.boolean "blocked", default: false
    t.boolean "highlighted", default: false
    t.bigint "creator_id"
    t.string "sender_type"
    t.datetime "received_at"
    t.datetime "read_at"
    t.string "external_id"
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
    t.string "project_name", default: "100eyes"
    t.string "onboarding_title", default: "Hallo und herzlich willkommen!"
    t.string "onboarding_byline", default: ""
    t.string "onboarding_data_processing_consent_additional_info", default: ""
    t.string "onboarding_page", default: "Wir freuen uns, dass Sie an unserer Dialog-Recherche zur Schweinehaltung in Deutschland teilnehmen. Denn dort zeigen sich überall schwerwiegende Probleme: Schlachthofskandale, menschenunwürdige Arbeitsbedingungen, Tierqualen, dazu ein rapider Preisverfall, der Schweinebauern ruiniert. So kann es nicht weitergehen. Das weiß jeder, der mit diesem Markt zu tun hat.\n\nLösungsvorschläge gibt es bisher keine. Deswegen starten wir diese Dialog-Recherche mit Ihrer Hilfe. Statt mit ein bis drei Betroffenen oder Experten ein Interview zu führen und dann einen Beitrag zu veröffentlichen, wollen wir mit vielen verschiedenen Menschen das Gespräch suchen. Und das über einen Zeitraum von vier Wochen. Damit wir ein breiteres Bild bekommen und Dinge besser verstehen.\n\nEs ist ein Experiment. Danke, dass Sie sich darauf einlassen.\n\n### Wer?\nHinter dem #Schweinesystem stecken Menschen, keine Maschinen: Die Journalisten Katharina Jakob und Jens Eber, der Filmemacher Oliver Eberhardt sowie das Dialog-Recherche-Team Isabelle Buckow, Astrid Csuraji und Dr. Jakob Vicari von tactile.news. [Auf unserer Webseite](https://tactile.news/ueber-uns) stellen wir unsere Idee vom Dialog-Journalismus ausführlicher vor.\n\n### Wie?\nWir stellen Ihnen in den nächsten vier, fünf Wochen immer mal wieder eine Frage. Am liebsten per Telegram Messenger. Wenn Sie den nicht nutzen und auch nicht installieren wollen (er ist sehr ähnlich wie WhatsApp), kommunizieren Sie mit uns per E-Mail. Es bleibt Ihnen überlassen, ob Sie jede Frage beantworten oder auch welche auslassen.\n\n### Wo?\nDamit wir Sie künftig auf dem Kanal Ihrer Wahl erreichen, teilen Sie uns bitte mit, ob wir Sie per E-Mail oder Telegram anschreiben sollen.\n"
    t.string "onboarding_success_heading", default: "Vielen Dank für Ihre Anmeldung bei 100eyes.\n"
    t.string "onboarding_success_text", default: "Unsere Dialog-Recherche startet bald. Wir melden uns dann bei Ihnen.\n\nUm unseren Kanal abzubestellen, schreibe „abbestellen“.\n"
    t.string "onboarding_unauthorized_heading", default: "Leider ist dieser Einladungs-Link nicht mehr gültig.\n"
    t.string "onboarding_unauthorized_text", default: "Das ist aber nicht Ihre Schuld! Bitte kontaktieren Sie uns unter support@100ey.es, um einen neuen Link zu erhalten.\n\n"
    t.string "onboarding_data_protection_link", default: "https://tactile.news/100eyes-datenschutz/"
    t.string "onboarding_imprint_link", default: "https://tactile.news/impressum/"
    t.boolean "onboarding_show_gdpr_modal", default: false
    t.boolean "onboarding_ask_for_additional_consent", default: false
    t.string "onboarding_additional_consent_heading", default: ""
    t.string "onboarding_additional_consent_text", default: ""
    t.string "telegram_unknown_content_message", default: "Unsere Software kann derzeit Textnachrichten, Sprachnachrichten und Bilder verarbeiten, jedoch noch keine weiteren Inhalte wie z.B. Sticker, Dateianhänge oder Kontakte. Für die Zwischenzeit bitten wir Sie, Nachrichten mit solchen Inhalten an @FrauCsu (Astrid Csuraji) zu schicken. Herzlichen Dank!\n"
    t.string "telegram_contributor_not_found_message", default: "Vielen Dank für Ihre Nachricht. Leider können wir Ihr Telegram-Konto noch nicht zuordnen.\n\nDafür benötigen wir den 8-stellige Code, den Sie während der Registrierung erhalten haben: Bitte schreiben Sie uns einfach eine Nachricht über Telegram hier in diesen Chat. Die Nachricht darf nur den Code enthalten und keinen weiteren Text.\n\nFalls das nicht klappt, melden Sie sich gerne unter support@tactile.news, dann lösen wir das Problem schnell. Vielen Dank.\n"
    t.string "encrypted_telegram_bot_api_key"
    t.string "encrypted_telegram_bot_api_key_iv"
    t.string "telegram_bot_username"
    t.string "threema_unknown_content_message", default: "Unsere Software kann derzeit Textnachrichten, Sprachnachrichten und Bilder verarbeiten, jedoch noch keine weiteren Inhalte wie z.B. Kontakte oder Dateianhänge. Für die Zwischenzeit bitten wir Sie, Nachrichten mit solchen Inhalten an Astrid Csuraji, ThreemaID 4N4Y3T2E zu schicken. Herzlichen Dank!\n"
    t.string "threemarb_api_identity"
    t.string "encrypted_threemarb_api_secret"
    t.string "encrypted_threemarb_api_secret_iv"
    t.string "encrypted_threemarb_private"
    t.string "encrypted_threemarb_private_iv"
    t.string "twilio_api_key_sid"
    t.string "encrypted_twilio_api_key_secret"
    t.string "encrypted_twilio_api_key_secret_iv"
    t.string "signal_server_phone_number"
    t.string "signal_monitoring_url"
    t.string "signal_unknown_content_message", default: "Unsere Software kann derzeit Textnachrichten, Sprachnachrichten, Bilder und Reaktionen auf Nachrichten verarbeiten, jedoch noch keine weiteren Inhalte wie z.B. Sticker oder Kontakte. In der Zwischenzeit senden Sie bitte Nachrichten mit solchen Inhalten an <KONTAKTDATEN EINFÜGEN>. Herzlichen Dank!\n"
    t.string "twilio_account_sid"
    t.string "whats_app_server_phone_number"
    t.string "three_sixty_dialog_whats_app_template_namespace"
    t.string "encrypted_three_sixty_dialog_client_api_key"
    t.string "encrypted_three_sixty_dialog_client_api_key_iv"
    t.string "three_sixty_dialog_client_id"
    t.string "three_sixty_dialog_client_waba_account_id"
    t.string "email_from_address"
    t.string "whats_app_profile_about", default: ""
    t.jsonb "onboarding_allowed", default: {"email"=>true, "signal"=>true, "threema"=>true, "telegram"=>true, "whats_app"=>true}
    t.jsonb "twilio_content_sids", default: {"new_request_day1"=>"", "new_request_day2"=>"", "new_request_day3"=>"", "new_request_night1"=>"", "new_request_night2"=>"", "new_request_night3"=>"", "new_request_evening1"=>"", "new_request_evening2"=>"", "new_request_evening3"=>"", "new_request_morning1"=>"", "new_request_morning2"=>"", "new_request_morning3"=>""}
    t.string "signal_complete_onboarding_link"
    t.jsonb "whats_app_quick_reply_button_text", default: {"more_info"=>"Mehr Infos", "answer_request"=>"Antworten"}
    t.string "whats_app_more_info_message", default: ""
    t.index ["business_plan_id"], name: "index_organizations_on_business_plan_id"
    t.index ["contact_person_id"], name: "index_organizations_on_contact_person_id"
    t.index ["telegram_bot_username"], name: "index_organizations_on_telegram_bot_username", unique: true
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "organization_id"
    t.index ["organization_id"], name: "index_pg_search_documents_on_organization_id"
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
    t.integer "replies_count", default: 0
    t.bigint "user_id"
    t.datetime "schedule_send_for"
    t.datetime "broadcasted_at"
    t.bigint "organization_id"
    t.string "whats_app_external_file_ids", default: [], array: true
    t.index ["organization_id"], name: "index_requests_on_organization_id"
    t.index ["user_id"], name: "index_requests_on_user_id"
    t.index ["whats_app_external_file_ids"], name: "index_requests_on_whats_app_external_file_ids", using: :gin
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
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
    t.datetime "deactivated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["remember_token"], name: "index_users_on_remember_token"
  end

  create_table "users_organizations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["organization_id"], name: "index_users_organizations_on_organization_id"
    t.index ["user_id"], name: "index_users_organizations_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_notifications", "contributors"
  add_foreign_key "activity_notifications", "messages"
  add_foreign_key "activity_notifications", "organizations"
  add_foreign_key "activity_notifications", "requests"
  add_foreign_key "activity_notifications", "users"
  add_foreign_key "contributors", "organizations"
  add_foreign_key "json_web_tokens", "contributors"
  add_foreign_key "message_files", "messages"
  add_foreign_key "messages", "contributors", column: "recipient_id"
  add_foreign_key "messages", "requests"
  add_foreign_key "organizations", "business_plans"
  add_foreign_key "organizations", "users", column: "contact_person_id"
  add_foreign_key "pg_search_documents", "organizations"
  add_foreign_key "photos", "messages"
  add_foreign_key "requests", "organizations"
  add_foreign_key "requests", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "users", "organizations"
  add_foreign_key "users_organizations", "organizations"
  add_foreign_key "users_organizations", "users"
end
