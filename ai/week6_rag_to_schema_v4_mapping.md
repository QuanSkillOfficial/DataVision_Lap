# Week 6 RAG to Schema v4 Mapping

## Objective

This mapping documents the Week 6 handoff from Lap's RAG pipeline to Phat's schema v4-compatible tables.

## Confirmed field mappings

- documents.document_external_id: Lap's document identifier (string) for external lookup
- documents.id: Integer primary key used for foreign keys in document_chunks and rag_query_logs
- document_chunks.chunk_id: Stable chunk identifier derived from the source page and chunk index
- document_chunks.document_id: Integer foreign key into documents.id
- document_chunks.embedding: Vector(384) embedding payload
- document_chunks.chunk_metadata: JSONB metadata including page_number, file_name, source, and other citation info
- rag_query_logs fields: document_id, user_query, retrieved_chunk_ids, retrieval_scores, generated_response, answer_confidence, latency_ms, model_name

## Lap to Phat flow

1. Load Duy document pages as JSONL.
2. Convert pages to chunks with page-aware IDs.
3. Resolve the external document ID to documents.id using documents.document_external_id.
4. Generate a 384-dimensional embedding for each chunk.
5. Insert rows into the existing document_chunks table.
6. Write retrieval logs into rag_query_logs.

## Notes

- Lap should not create production tables independently; it should validate the schema and use the existing tables.
- Integer foreign keys should be used for all production inserts.
- String document IDs should not be inserted into integer FK columns.
