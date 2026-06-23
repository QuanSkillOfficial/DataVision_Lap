# Lap RAG to Phat Schema v3 Mapping

## Overview

This document maps Lap's RAG system fields to Phat's database schema_v3. Lap should not create a separate table structure independently - all data should align with Phat's schema.

## Field Mapping

### document_chunks Table

| Lap Field | Phat Table.Column | Data Type | Notes |
|-----------|------------------|-----------|-------|
| chunk_id | document_chunks.chunk_id | VARCHAR(255) UNIQUE | Unique identifier for each chunk |
| chunk_text | document_chunks.chunk_text | TEXT | The actual text content of the chunk |
| embedding | document_chunks.embedding | vector(384) | 384-dimensional embedding from all-MiniLM-L6-v2 |
| page_number | document_chunks.page_number | INTEGER | Page number from original document |
| metadata | document_chunks.chunk_metadata | JSONB | Additional metadata (file_name, source, etc.) |

### Document ID Strategy

**Lap/Duy document_id (string)** → Phat's `document_external_id` / `document_key`
- Example: "doc_001", "dataflow_v1", "policy_2024"
- This is the external identifier used by the RAG system

**Phat documents.id (integer)** → Database Foreign Key
- Example: 1, 2, 3, 42
- This is the internal database primary key
- Used for foreign key relationships in document_chunks

### Relationship

```
documents table (Phat)
├─ id (INTEGER, PK)
├─ document_external_id (VARCHAR) - maps to Lap's document_id
├─ document_key (VARCHAR) - alternative identifier
└─ ... other fields

document_chunks table (Phat)
├─ id (INTEGER, PK)
├─ chunk_id (VARCHAR, UNIQUE) - Lap's chunk_id
├─ document_id (INTEGER, FK) - references documents.id
├─ chunk_text (TEXT)
├─ embedding (vector(384))
├─ page_number (INTEGER)
└─ chunk_metadata (JSONB) - Lap's metadata
```

## Embedding Specifications

- **Model**: all-MiniLM-L6-v2
- **Dimension**: 384
- **Similarity Metric**: cosine similarity
- **Index Type**: ivfflat with vector_cosine_ops

## Metadata Fields (chunk_metadata JSONB)

The chunk_metadata JSONB field should contain:
```json
{
  "file_name": "sample.pdf",
  "source": "sample.pdf",
  "page_number": 1,
  "character_count": 512,
  "chunk_index": 0,
  "start_char": 0,
  "end_char": 512
}
```

## Chunk ID Format

Lap's chunk_id format: `{document_id}_page_{page_number}_chunk_{chunk_num:03d}`
- Example: `doc_001_page_4_chunk_002`
- Example: `dataflow_v1_page_12_chunk_005`

## Database Connection Requirements

- **Extension**: pgvector must be enabled
- **Connection String**: PostgreSQL connection with pgvector support
- **Table Creation**: Lap should rely on Phat's schema_v3.sql, not create tables independently

## Migration Notes

1. Lap's current vector_store.py uses `document_id` as VARCHAR - this should map to Phat's `document_external_id`
2. The foreign key `document_id` in document_chunks is an INTEGER referencing documents.id
3. Lap should store both:
   - `document_external_id` (VARCHAR) in metadata for RAG operations
   - `document_id` (INTEGER FK) for database relationships

## Implementation Priority

1. ✅ Update vector_store.py to use Phat's column names
2. ✅ Ensure chunk_id format matches Phat's expectations
3. ✅ Store document_external_id in chunk_metadata
4. ✅ Use INTEGER document_id FK when inserting into document_chunks
5. ✅ Align embedding dimension to 384
6. ✅ Use cosine similarity for vector operations

## Testing Checklist

- [ ] Chunks can be inserted into document_chunks table
- [ ] Embeddings are stored as vector(384)
- [ ] Similarity search returns correct chunk_id, page_number, and metadata
- [ ] Citations include file_name, page_number, chunk_id
- [ ] Document ID mapping works correctly (external_id ↔ FK)
