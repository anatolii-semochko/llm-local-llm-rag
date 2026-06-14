-- Initialize database for future RAG implementation
CREATE EXTENSION IF NOT EXISTS vector;

-- Future RAG tables will be created here
-- CREATE TABLE documents (
--     id BIGSERIAL PRIMARY KEY,
--     content TEXT NOT NULL,
--     embedding VECTOR(768),
--     metadata JSONB,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);