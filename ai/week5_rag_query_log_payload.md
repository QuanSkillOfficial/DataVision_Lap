# RAG Query Log Payload Specification

## Overview

This document specifies the payload format for logging RAG queries to the `rag_query_logs` table in Phat's database. This enables analytics, debugging, and performance monitoring of the RAG system.

## Log Payload Structure

```json
{
  "document_id": 1,
  "user_query": "What is the data pipeline?",
  "retrieved_chunk_ids": [
    "doc_001_page_4_chunk_002",
    "doc_001_page_5_chunk_000"
  ],
  "retrieval_scores": [0.84, 0.79],
  "generated_response": null,
  "answer_confidence": 0.84,
  "latency_ms": 320,
  "model_name": "all-MiniLM-L6-v2"
}
```

## Field Descriptions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| document_id | INTEGER | Foreign key to documents.id | 1 |
| user_query | STRING | The user's question | "What is the data pipeline?" |
| retrieved_chunk_ids | ARRAY[STRING] | List of chunk IDs retrieved | ["doc_001_page_4_chunk_002"] |
| retrieval_scores | ARRAY[FLOAT] | Similarity scores for each chunk | [0.84, 0.79] |
| generated_response | STRING \| NULL | The generated answer (or NULL if retrieval-only) | "The data pipeline is..." |
| answer_confidence | FLOAT | Confidence score (0.0-1.0) | 0.84 |
| latency_ms | FLOAT | Query latency in milliseconds | 320.5 |
| model_name | STRING | Embedding model used | "all-MiniLM-L6-v2" |

## Database Schema (Phat's schema_v3)

```sql
CREATE TABLE rag_query_logs (
    id SERIAL PRIMARY KEY,
    document_id INTEGER NOT NULL,
    user_query TEXT NOT NULL,
    retrieved_chunk_ids TEXT[],
    retrieval_scores FLOAT[],
    generated_response TEXT,
    answer_confidence FLOAT,
    latency_ms FLOAT,
    model_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_document FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
);

CREATE INDEX idx_rag_query_logs_document_id ON rag_query_logs (document_id);
CREATE INDEX idx_rag_query_logs_created_at ON rag_query_logs (created_at);
```

## Usage Example

### Python (rag_service.py)

```python
from ai.rag.rag_service import RAGService

# Create service
service = create_rag_service(
    connection_string="postgresql://user:pass@localhost/datavision",
    use_pgvector=True
)

# Execute query
response = service.retrieve_context(
    question="What is the data pipeline?",
    document_id=1,
    top_k=5
)

# Build log payload
log_payload = service.log_rag_query(
    document_id=1,
    user_query=response["question"],
    retrieved_chunk_ids=[c["chunk_id"] for c in response["retrieved_context"]],
    retrieval_scores=[c["score"] for c in response["retrieved_context"]],
    generated_response=response.get("answer"),
    answer_confidence=response.get("metadata", {}).get("confidence", 0.0),
    latency_ms=response.get("metadata", {}).get("latency_ms", 0),
    model_name=response["model"]
)

# Insert into database (implementation depends on Phat's logging infrastructure)
# insert_rag_query_log(log_payload)
```

## Status Values

The `generated_response` field can be:
- `NULL`: Retrieval-only mode (no LLM used)
- String: Generated answer from LLM
- "I do not know based on the provided documents.": Explicit no-answer response

## Confidence Scoring

Confidence is calculated based on:
- Average similarity score of retrieved chunks
- Top similarity score
- Whether the answer contains "I do not know" phrases
- Number of chunks retrieved

Typical ranges:
- 0.0-0.3: Low confidence (likely no answer)
- 0.3-0.6: Medium confidence (partial match)
- 0.6-0.8: Good confidence (relevant context found)
- 0.8-1.0: High confidence (strong match)

## Analytics Use Cases

This log data enables:
1. **Query analytics**: Most common queries, success rates
2. **Performance monitoring**: Average latency, P95/P99 latency
3. **Retrieval quality**: Average similarity scores, hit rates
4. **Document usage**: Which documents are queried most
5. **Debugging**: Trace failed queries, low-confidence responses
6. **Model evaluation**: Compare performance across different embedding models

## Integration Points

- **RAG Service**: `rag_service.py` builds the payload via `log_rag_query()`
- **Backend/FastAPI**: Should call logging after each RAG query
- **Phat's Database**: Stores logs in `rag_query_logs` table
- **Analytics Dashboard**: Can query logs for metrics and visualizations

## Future Enhancements

Potential additions:
- `user_id`: Track queries per user
- `session_id`: Group queries by session
- `query_type`: Categorize queries (e.g., "definition", "procedure", "comparison")
- `feedback_score`: User feedback on answer quality
- `llm_tokens_used`: Token count for LLM calls
- `embedding_version`: Track embedding model versions
