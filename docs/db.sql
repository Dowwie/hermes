CREATE TABLE party (
    id BIGSERIAL PRIMARY KEY,
    ext_id UUID NOT NULL DEFAULT gen_random_uuid(),
    party_name TEXT,
    email TEXT,
    phone_e164 VARCHAR(30),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_party_ext_id ON party(ext_id);
CREATE UNIQUE INDEX idx_party_email ON party(email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX idx_party_phone ON party(phone_e164) WHERE phone_e164 IS NOT NULL;



CREATE TABLE provider (
    id BIGSERIAL PRIMARY KEY,
    ext_id UUID NOT NULL DEFAULT gen_random_uuid(),
    provider_name TEXT NOT NULL,
    service_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_provider_name 
        UNIQUE (provider_name)        
);
CREATE INDEX idx_provider_ext_id ON provider(ext_id);
CREATE UNIQUE INDEX idx_provider_name ON provider(provider_name);



CREATE TABLE channel (
    id BIGSERIAL PRIMARY KEY,
    ext_id UUID NOT NULL DEFAULT gen_random_uuid(),
    provider_id BIGINT NOT NULL REFERENCES provider(id),
    channel_name VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_channel
        UNIQUE (provider_id, channel_name)
);
CREATE INDEX idx_channel_ext_id ON channel(ext_id);


CREATE TABLE conversation (
    id BIGSERIAL PRIMARY KEY,
    ext_id UUID NOT NULL DEFAULT gen_random_uuid(),
    party_a_id BIGINT NOT NULL REFERENCES party(id),
    party_b_id BIGINT NOT NULL REFERENCES party(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_conversation
        UNIQUE (party_a_id, party_b_id),
    CONSTRAINT unique_party_pair
        CHECK (party_a_id < party_b_id)
);
CREATE INDEX idx_conversation_ext_id ON conversation(ext_id);


CREATE TABLE message (
    id BIGSERIAL PRIMARY KEY,
    ext_id UUID NOT NULL DEFAULT gen_random_uuid(),
    conversation_id BIGINT NOT NULL REFERENCES conversation(id),
    channel_id BIGINT NOT NULL REFERENCES channel(id),
    sender_id BIGINT NOT NULL REFERENCES party(id),
    recipient_id BIGINT NOT NULL REFERENCES party(id),
    body TEXT,
    sent_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_message_ext_id ON message(ext_id);


CREATE TABLE attachment (
    id BIGSERIAL PRIMARY KEY,
    ext_id UUID NOT NULL DEFAULT gen_random_uuid(),
    message_id BIGINT NOT NULL REFERENCES message(id),
    url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_attachment_ext_id ON attachment(ext_id);
