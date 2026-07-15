# Week 7 RAG Query Log Insert Result

**Author:** Lap (RAG / Vector Search Module Owner)
**Week:** 7
**Date:** July 2026

## Purpose

Document the RAG query log insertion into Phat's rag_query_logs table for analytics and monitoring.

## Query Log Table Schema

### Table: rag_query_logs

```sql
CREATE TABLE rag_query_logs (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id),
    query_text TEXT NOT NULL,
    retrieved_chunk_ids TEXT[],
    retrieval_scores FLOAT[],
    top_k INTEGER,
    latency_ms INTEGER,
    status TEXT,
    model_name TEXT,
    embedding_dimension INTEGER,
    generated_response TEXT,
    answer_confidence FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Query Log Payload

### Sample Payload

```json
{
  "document_id": 1,
  "query_text": "What is the DataFlow pipeline?",
  "retrieved_chunk_ids": [
    "doc_dataflow_technical_report_page_4_chunk_000",
    "doc_dataflow_technical_report_page_5_chunk_001",
    "doc_dataflow_technical_report_page_3_chunk_000",
    "doc_dataflow_technical_report_page_6_chunk_000",
    "doc_dataflow_technical_report_page_7_chunk_000"
  ],
  "retrieval_scores": [0.84, 0.79, 0.76, 0.72, 0.68],
  "top_k": 5,
  "latency_ms": 45,
  "status": "retrieval_only",
  "model_name": "all-MiniLM-L6-v2",
  "embedding_dimension": 384,
  "generated_response": null,
  "answer_confidence": 0.84,
  "created_at": "2026-07-16T01:42:00Z"
}
```

## Insertion Function

### Function: insert_rag_query_log

```python
import json
from typing import Dict, Optional

def insert_rag_query_log(conn, log_payload: Dict) -> int:
    """
    Insert RAG query log into rag_query_logs table.
    
    Args:
        conn: Database connection
        log_payload: Dictionary with query log data
    
    Returns:
        Inserted log ID
    """
    cursor = conn.cursor()
    
    query = """
        INSERT INTO rag_query_logs (
            document_id,
            query_text,
            retrieved_chunk_ids,
            retrieval_scores,
            top_k,
            latency_ms,
            status,
            model_name,
            embedding_dimension,
            generated_response,
            answer_confidence
        ) VALUES (
            %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
        ) RETURNING id
    """
    
    params = (
        log_payload["document_id"],
        log_payload["query_text"],
        log_payload["retrieved_chunk_ids"],
        log_payload["retrieval_scores"],
        log_payload["top_k"],
        log_payload["latency_ms"],
        log_payload["status"],
        log_payload["model_name"],
        log_payload["embedding_dimension"],
        log_payload["generated_response"],
        log_payload["answer_confidence"]
    )
    
    cursor.execute(query, params)
    log_id = cursor.fetchone()[0]
    conn.commit()
    cursor.close()
    
    return log_id
```

## Integration with RAG Pipeline

### Automatic Query Logging

The RAG service should automatically log queries after retrieval:

```python
from ai.rag.rag_service import RAGService

def retrieve_context_with_logging(
    self,
    query: str,
    document_id: int,
    top_k: int = 5
) -> Dict:
    """Retrieve context and log the query."""
    
    # Retrieve context
    response = self.retrieve_context(query, document_id, top_k)
    
    # Build log payload
    log_payload = {
        "document_id": document_id,
        "query_text": query,
        "retrieved_chunk_ids": [c["chunk_id"] for c in response["retrieved_context"]],
        "retrieval_scores": [c["similarity_score"] for c in response["retrieved_context"]],
        "top_k": top_k,
        "latency_ms": response["metadata"]["latency_ms"],
        "status": response["status"],
        "model_name": response["model"],
        "embedding_dimension": response["metadata"].get("embedding_dimension", 384),
        "generated_response": response.get("answer"),
        "answer_confidence": response["metadata"].get("answer_confidence", 0.0)
    }
    
    # Insert log
    if self.vector_store.connection:
        log_id = insert_rag_query_log(self.vector_store.connection, log_payload)
        response["metadata"]["log_id"] = log_id
    
    return response
```

## Validation Queries

### Check Query Log Count

```sql
SELECT COUNT(*) as total_queries 
FROM rag_query_logs;
```

**Expected**: At least 1 after Week 7

### Check Daily Metrics View

```sql
SELECT * FROM v_rag_daily_metrics;
```

**Expected**: Non-empty after Week 7

### Sample Daily Metrics View

```sql
CREATE VIEW v_rag_daily_metrics AS
SELECT 
    DATE(created_at) as query_date,
    COUNT(*) as total_queries,
    AVG(latency_ms) as avg_latency_ms,
    AVG(answer_confidence) as avg_confidence,
    COUNT(DISTINCT document_id) as unique_documents,
    COUNT(CASE WHEN status = 'retrieval_only' THEN 1 END) as retrieval_only_count,
    COUNT(CASE WHEN status = 'answered' THEN 1 END) as answered_count
FROM rag_query_logs
GROUP BY DATE(created_at)
ORDER BY query_date DESC;
```

## Query Log Analytics

### Key Metrics to Track

1. **Query Volume**: Number of queries per day
2. **Latency**: Average query latency in milliseconds
3. **Confidence**: Average answer confidence score
4. **Document Usage**: Number of unique documents queried
5. **Status Distribution**: Retrieval-only vs answered queries

### Sample Analytics Queries

#### Average Latency by Document

```sql
SELECT 
    d.document_external_id,
    d.file_name,
    AVG(rql.latency_ms) as avg_latency_ms,
    COUNT(*) as query_count
FROM rag_query_logs rql
JOIN documents d ON rql.document_id = d.id
GROUP BY d.id, d.document_external_id, d.file_name
ORDER BY avg_latency_ms;
```

#### Top Queries

```sql
SELECT 
    query_text,
    COUNT(*) as frequency,
    AVG(answer_confidence) as avg_confidence
FROM rag_query_logs
GROUP BY query_text
ORDER BY frequency DESC
LIMIT 10;
```

#### Retrieval Performance

```sql
SELECT 
    DATE(created_at) as query_date,
    AVG(retrieval_scores[1]) as avg_top1_score,
    AVG(retrieval_scores[1]) as avg_top3_score_avg,
    COUNT(*) as total_queries
FROM rag_query_logs
WHERE retrieval_scores IS NOT NULL AND array_length(retrieval_scores, 1) > 0
GROUP BY DATE(created_at)
ORDER BY query_date;
```

## Week 7 Insertion Result

### Insertion Status

**Status**: Template for real insertion

**Log ID**: Pending database insertion

**Document ID**: 1

**Query**: "What is the DataFlow pipeline?"

**Retrieved Chunks**: 5

**Latency**: 45ms

**Status**: retrieval_only

### Expected Database State After Insertion

```sql
-- After insertion
SELECT COUNT(*) FROM rag_query_logs;
-- Expected: 1

SELECT * FROM v_rag_daily_metrics;
-- Expected: 1 row with query_date = 2026-07-16

SELECT query_text, COUNT(*) FROM rag_query_logs GROUP BY query_text;
-- Expected: 1 row for "What is the DataFlow pipeline?"
```

## Error Handling

### Common Errors

#### Error: Table does not exist
```
RuntimeError: Table rag_query_logs does not exist
```
**Solution**: Ensure Phat has created rag_query_logs table

#### Error: Foreign key constraint
```
RuntimeError: Foreign key constraint violation on document_id
```
**Solution**: Ensure document_id exists in documents table

#### Error: Array type mismatch
```
RuntimeError: Array type mismatch for retrieved_chunk_ids
```
**Solution**: Ensure retrieved_chunk_ids is a TEXT[] array

## Integration Status

**Status**: Template for real insertion

**Database Connection**: Pending Phat's database setup

**Table Creation**: Pending Phat's schema execution

**Insertion**: Pending database availability

**Validation**: Pending insertion execution

**Next Steps**:
1. Ensure rag_query_logs table exists in Phat's database
2. Test insert_rag_query_log function with sample payload
3. Validate insertion with COUNT query
4. Validate v_rag_daily_metrics view returns data
5. Integrate automatic logging into RAG service
6. Monitor query logs for analytics

## Notes for Phat

1. **Table Schema**: Ensure rag_query_logs table matches expected schema
2. **Array Types**: Ensure retrieved_chunk_ids is TEXT[] and retrieval_scores is FLOAT[]
3. **Foreign Key**: Ensure document_id references documents(id)
4. **View**: Create v_rag_daily_metrics view for analytics
5. **Permissions**: Ensure Lap has INSERT permission on rag_query_logs
6. **Indexing**: Consider indexing on created_at and document_id for performance

## Notes for Team

1. **Analytics**: Query logs enable RAG performance monitoring
2. **Debugging**: Logs help debug retrieval issues
3. **Improvement**: Metrics guide RAG system improvements
4. **Usage Tracking**: Track which documents are queried most
5. **Quality Monitoring**: Monitor confidence scores over time

## Conclusion

RAG query logging provides essential analytics for monitoring and improving the RAG system. The logs track query patterns, performance metrics, and retrieval quality, enabling data-driven decisions for system optimization.

The integration with Phat's rag_query_logs table ensures centralized logging and analytics across the platform.
