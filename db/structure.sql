SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: user_otp_module; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_otp_module AS ENUM (
    'enabled',
    'disabled'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: action_mailbox_inbound_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.action_mailbox_inbound_emails (
    id bigint NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    message_id character varying NOT NULL,
    message_checksum character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: action_mailbox_inbound_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.action_mailbox_inbound_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: action_mailbox_inbound_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.action_mailbox_inbound_emails_id_seq OWNED BY public.action_mailbox_inbound_emails.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: contributors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contributors (
    id bigint NOT NULL,
    email character varying,
    telegram_chat_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    username character varying,
    first_name character varying,
    last_name character varying,
    telegram_id integer,
    avatar_url character varying,
    note character varying,
    zip_code character varying,
    city character varying,
    phone character varying,
    deactivated_at timestamp without time zone
);


--
-- Name: contributors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contributors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contributors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contributors_id_seq OWNED BY public.contributors.id;


--
-- Name: json_web_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.json_web_tokens (
    id bigint NOT NULL,
    invalidated_jwt character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: json_web_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.json_web_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: json_web_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.json_web_tokens_id_seq OWNED BY public.json_web_tokens.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    sender_id integer,
    request_id bigint NOT NULL,
    text character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    telegram_media_group_id character varying,
    photos_count integer,
    recipient_id bigint,
    broadcasted boolean DEFAULT false,
    unknown_content boolean DEFAULT false,
    blocked boolean DEFAULT false,
    highlighted boolean DEFAULT false
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: pg_search_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pg_search_documents (
    id bigint NOT NULL,
    content text,
    searchable_type character varying,
    searchable_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pg_search_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pg_search_documents_id_seq OWNED BY public.pg_search_documents.id;


--
-- Name: photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.photos (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.photos_id_seq OWNED BY public.photos.id;


--
-- Name: requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requests (
    id bigint NOT NULL,
    title character varying,
    text character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    hints character varying[] DEFAULT '{}'::character varying[],
    replies_count integer
);


--
-- Name: requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requests_id_seq OWNED BY public.requests.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    var character varying NOT NULL,
    value text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_type character varying,
    taggable_id integer,
    tagger_type character varying,
    tagger_id integer,
    context character varying(128),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taggings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taggings_id_seq OWNED BY public.taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    taggings_count integer DEFAULT 0
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    email character varying NOT NULL,
    encrypted_password character varying(128) NOT NULL,
    confirmation_token character varying(128),
    remember_token character varying(128) NOT NULL,
    otp_secret_key character varying,
    otp_module public.user_otp_module DEFAULT 'disabled'::public.user_otp_module
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: voices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voices (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: voices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.voices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: voices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.voices_id_seq OWNED BY public.voices.id;


--
-- Name: action_mailbox_inbound_emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_mailbox_inbound_emails ALTER COLUMN id SET DEFAULT nextval('public.action_mailbox_inbound_emails_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: contributors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contributors ALTER COLUMN id SET DEFAULT nextval('public.contributors_id_seq'::regclass);


--
-- Name: json_web_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.json_web_tokens ALTER COLUMN id SET DEFAULT nextval('public.json_web_tokens_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: pg_search_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pg_search_documents ALTER COLUMN id SET DEFAULT nextval('public.pg_search_documents_id_seq'::regclass);


--
-- Name: photos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photos ALTER COLUMN id SET DEFAULT nextval('public.photos_id_seq'::regclass);


--
-- Name: requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests ALTER COLUMN id SET DEFAULT nextval('public.requests_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings ALTER COLUMN id SET DEFAULT nextval('public.taggings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: voices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voices ALTER COLUMN id SET DEFAULT nextval('public.voices_id_seq'::regclass);


--
-- Name: action_mailbox_inbound_emails action_mailbox_inbound_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_mailbox_inbound_emails
    ADD CONSTRAINT action_mailbox_inbound_emails_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: contributors contributors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contributors
    ADD CONSTRAINT contributors_pkey PRIMARY KEY (id);


--
-- Name: json_web_tokens json_web_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.json_web_tokens
    ADD CONSTRAINT json_web_tokens_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: pg_search_documents pg_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pg_search_documents
    ADD CONSTRAINT pg_search_documents_pkey PRIMARY KEY (id);


--
-- Name: photos photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photos
    ADD CONSTRAINT photos_pkey PRIMARY KEY (id);


--
-- Name: requests requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: voices voices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voices
    ADD CONSTRAINT voices_pkey PRIMARY KEY (id);


--
-- Name: index_action_mailbox_inbound_emails_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_action_mailbox_inbound_emails_uniqueness ON public.action_mailbox_inbound_emails USING btree (message_id, message_checksum);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_contributors_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_contributors_on_email ON public.contributors USING btree (email);


--
-- Name: index_contributors_on_telegram_chat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_contributors_on_telegram_chat_id ON public.contributors USING btree (telegram_chat_id);


--
-- Name: index_contributors_on_telegram_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_contributors_on_telegram_id ON public.contributors USING btree (telegram_id);


--
-- Name: index_messages_on_recipient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_recipient_id ON public.messages USING btree (recipient_id);


--
-- Name: index_messages_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_request_id ON public.messages USING btree (request_id);


--
-- Name: index_messages_on_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_sender_id ON public.messages USING btree (sender_id);


--
-- Name: index_messages_on_telegram_media_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_messages_on_telegram_media_group_id ON public.messages USING btree (telegram_media_group_id);


--
-- Name: index_pg_search_documents_on_searchable_type_and_searchable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pg_search_documents_on_searchable_type_and_searchable_id ON public.pg_search_documents USING btree (searchable_type, searchable_id);


--
-- Name: index_photos_on_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_photos_on_message_id ON public.photos USING btree (message_id);


--
-- Name: index_settings_on_var; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_var ON public.settings USING btree (var);


--
-- Name: index_taggings_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_context ON public.taggings USING btree (context);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tag_id ON public.taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_id ON public.taggings USING btree (taggable_id);


--
-- Name: index_taggings_on_taggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_type ON public.taggings USING btree (taggable_type);


--
-- Name: index_taggings_on_tagger_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id ON public.taggings USING btree (tagger_id);


--
-- Name: index_taggings_on_tagger_id_and_tagger_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id_and_tagger_type ON public.taggings USING btree (tagger_id, tagger_type);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_remember_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_remember_token ON public.users USING btree (remember_token);


--
-- Name: index_voices_on_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_voices_on_message_id ON public.voices USING btree (message_id);


--
-- Name: taggings_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX taggings_idx ON public.taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: taggings_idy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_idy ON public.taggings USING btree (taggable_id, taggable_type, tagger_id, context);


--
-- Name: taggings_taggable_context_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_taggable_context_idx ON public.taggings USING btree (taggable_id, taggable_type, context);


--
-- Name: messages fk_rails_256e4b72c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_256e4b72c5 FOREIGN KEY (sender_id) REFERENCES public.contributors(id);


--
-- Name: messages fk_rails_273a25a7a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_273a25a7a6 FOREIGN KEY (recipient_id) REFERENCES public.contributors(id);


--
-- Name: voices fk_rails_308ebcad6c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voices
    ADD CONSTRAINT fk_rails_308ebcad6c FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: taggings fk_rails_9fcd2e236b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT fk_rails_9fcd2e236b FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: messages fk_rails_d6c80833f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_d6c80833f0 FOREIGN KEY (request_id) REFERENCES public.requests(id);


--
-- Name: photos fk_rails_f6f9345f04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photos
    ADD CONSTRAINT fk_rails_f6f9345f04 FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20200406192204'),
('20200406192305'),
('20200407194509'),
('20200407195158'),
('20200415183727'),
('20200417134641'),
('20200420113042'),
('20200420113229'),
('20200425151350'),
('20200425151351'),
('20200505152543'),
('20200505153245'),
('20200515151637'),
('20200521134355'),
('20200521153806'),
('20200526171425'),
('20200530200004'),
('20200530205945'),
('20200530212247'),
('20200606140853'),
('20200612124611'),
('20200612212833'),
('20200613115522'),
('20200614220817'),
('20200819093111'),
('20200921150716'),
('20200921150717'),
('20200921150718'),
('20200921150719'),
('20200921150720'),
('20200921150721'),
('20200923174724'),
('20200924103822'),
('20200924142215'),
('20201016203534'),
('20201017105553'),
('20201031114456'),
('20201110232258'),
('20201126192714'),
('20201205191150');


