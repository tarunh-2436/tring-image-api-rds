CREATE TABLE IF NOT EXISTS images (

    image_id UUID PRIMARY KEY,

    owner_id UUID NOT NULL,

    filename VARCHAR(255) NOT NULL,

    status VARCHAR(20) NOT NULL,

    created_at TIMESTAMP NOT NULL,

    processed_at TIMESTAMP,

    file_size BIGINT,

    content_type VARCHAR(100),

    extension VARCHAR(20)
);

CREATE INDEX IF NOT EXISTS idx_owner_created
ON images(owner_id, created_at DESC);