# Week 7 RAG API Contract (FastAPI-Ready)

**Author:** Lap (RAG / Vector Search Module Owner)
**Week:** 7
**Date:** July 2026

## Purpose

Define the FastAPI-ready RAG service contract for Week 8/9 staging MVP integration.

## API Overview

### Base URL
```
http://localhost:8000/api/v1/rag
```

### Authentication
- **Type**: API Key or JWT (to be determined)
- **Header**: `Authorization: Bearer <token>`

## Endpoints

### POST /retrieve

Retrieve relevant context for a query using RAG.

#### Request

```python
from pydantic import BaseModel, Field
from typing import Optional, List

class RetrieveRequest(BaseModel):
    query: str = Field(..., description="User query to retrieve context for")
    document_id: Optional[int] = Field(None, description="Filter by document ID")
    document_external_id: Optional[str] = Field(None, description="Filter by document external ID")
    top_k: int = Field(5, ge=1, le=20, description="Number of chunks to retrieve")
    min_score: float = Field(0.0, ge=0.0, le=1.0, description="Minimum similarity score threshold")
    include_answer: bool = Field(False, description="Whether to generate answer (future)")
    document_type_filter: Optional[str] = Field(None, description="Filter by document type (if safe)")
```

#### Response

```python
class RetrieveResponse(BaseModel):
    question: str
    answer: Optional[str]
    status: str  # "retrieval_only" or "answered"
    document_external_id: Optional[str]
    document_db_id: Optional[int]
    file_name: Optional[str]
    model: str
    retrieved_context: List[dict]
    citations: List[dict]
    metadata: dict
```

#### Example Request

```json
{
  "query": "What is the DataFlow pipeline?",
  "document_external_id": "doc_dataflow_technical_report",
  "top_k": 5,
  "min_score": 0.5,
  "include_answer": false
}
```

#### Example Response

```json
{
  "question": "What is the DataFlow pipeline?",
  "answer": null,
  "status": "retrieval_only",
  "document_external_id": "doc_dataflow_technical_report",
  "document_db_id": 1,
  "file_name": "DataFlow_Technical_Report.pdf",
  "model": "all-MiniLM-L6-v2",
  "retrieved_context": [
    {
      "chunk_id": "doc_dataflow_technical_report_page_4_chunk_000",
      "document_db_id": 1,
      "document_external_id": "doc_dataflow_technical_report",
      "file_name": "DataFlow_Technical_Report.pdf",
      "page_number": 4,
      "chunk_text": "The DataFlow pipeline consists of three main stages...",
      "similarity_score": 0.84
    }
  ],
  "citations": [
    {
      "file_name": "DataFlow_Technical_Report.pdf",
      "page_number": 4,
      "chunk_id": "doc_dataflow_technical_report_page_4_chunk_000"
    }
  ],
  "metadata": {
    "retrieval_backend": "pgvector",
    "embedding_dimension": 384,
    "top_k": 5,
    "latency_ms": 45,
    "num_chunks_retrieved": 5,
    "answer_confidence": 0.84,
    "filter_mode": "none",
    "filter_applied": false
  }
}
```

### POST /ingest

Ingest document pages into the RAG system.

#### Request

```python
class IngestRequest(BaseModel):
    document_pages_path: str = Field(..., description="Path to document_pages.jsonl file")
    document_external_id: str = Field(..., description="Document external ID")
    chunk_size: int = Field(512, ge=100, le=2000, description="Character size for chunks")
    overlap: int = Field(50, ge=0, le=500, description="Character overlap between chunks")
    skip_duplicates: bool = Field(True, description="Whether to skip duplicate chunks")
```

#### Response

```python
class IngestResponse(BaseModel):
    status: str
    document_external_id: str
    document_db_id: Optional[int]
    pages_loaded: int
    non_empty_pages: int
    empty_pages_skipped: int
    total_characters: int
    chunks_created: int
    chunks_inserted: int
    duplicate_chunks_skipped: int
    embeddings_generated: int
    embedding_dimension: int
    insertion_time_ms: float
    total_time_ms: float
    errors: List[str]
```

#### Example Request

```json
{
  "document_pages_path": "outputs/rag_handoff/week7_document_pages_db_enriched.jsonl",
  "document_external_id": "doc_dataflow_technical_report",
  "chunk_size": 512,
  "overlap": 50,
  "skip_duplicates": true
}
```

#### Example Response

```json
{
  "status": "success",
  "document_external_id": "doc_dataflow_technical_report",
  "document_db_id": 1,
  "pages_loaded": 36,
  "non_empty_pages": 36,
  "empty_pages_skipped": 0,
  "total_characters": 15234,
  "chunks_created": 35,
  "chunks_inserted": 35,
  "duplicate_chunks_skipped": 0,
  "embeddings_generated": 35,
  "embedding_dimension": 384,
  "insertion_time_ms": 1250,
  "total_time_ms": 2100,
  "errors": []
}
```

### GET /health

Health check endpoint.

#### Response

```python
class HealthResponse(BaseModel):
    status: str
    database_connected: bool
    embedding_model_loaded: bool
    version: str
```

#### Example Response

```json
{
  "status": "healthy",
  "database_connected": true,
  "embedding_model_loaded": true,
  "version": "1.0.0"
}
```

### GET /documents

List available documents.

#### Query Parameters
- `limit`: Maximum number of documents to return (default: 50)
- `offset`: Offset for pagination (default: 0)

#### Response

```python
class DocumentListResponse(BaseModel):
    documents: List[dict]
    total: int
    limit: int
    offset: int
```

#### Example Response

```json
{
  "documents": [
    {
      "document_db_id": 1,
      "document_external_id": "doc_dataflow_technical_report",
      "file_name": "DataFlow_Technical_Report.pdf",
      "page_count": 36,
      "chunk_count": 35,
      "ingested_at": "2026-07-16T01:42:00Z"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

## Data Models

### RetrievedContext

```python
class RetrievedContext(BaseModel):
    chunk_id: str
    document_db_id: int
    document_external_id: str
    file_name: str
    page_number: int
    chunk_text: str
    similarity_score: float
```

### Citation

```python
class Citation(BaseModel):
    file_name: str
    page_number: int
    chunk_id: str
```

### ResponseMetadata

```python
class ResponseMetadata(BaseModel):
    retrieval_backend: str  # "pgvector" or "in_memory"
    embedding_dimension: int
    top_k: int
    latency_ms: int
    num_chunks_retrieved: int
    answer_confidence: float
    filter_mode: str  # "none", "soft", "hard"
    filter_applied: bool
    filter_reason: Optional[str]
```

## Error Responses

### Standard Error Format

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| INVALID_REQUEST | 400 | Request validation failed |
| DOCUMENT_NOT_FOUND | 404 | Document not found |
| DATABASE_ERROR | 500 | Database connection or query error |
| EMBEDDING_ERROR | 500 | Embedding generation error |
| INTERNAL_ERROR | 500 | Internal server error |

### Example Error Response

```json
{
  "error": {
    "code": "DOCUMENT_NOT_FOUND",
    "message": "Document with external_id 'doc_invalid' not found",
    "details": {
      "document_external_id": "doc_invalid"
    }
  }
}
```

## FastAPI Implementation

### Example FastAPI Application

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent.parent))

from ai.rag.rag_service import RAGService
from ai.rag.embedder import Embedder
from ai.rag.vector_store import VectorStore
from ai.rag.load_document_pages_to_pgvector import load_and_ingest

app = FastAPI(title="RAG API", version="1.0.0")

# Initialize RAG components
embedder = Embedder()
vector_store = VectorStore(use_pgvector=True)
retriever = Retriever(embedder=embedder, vector_store=vector_store, top_k=5)
rag_service = RAGService(embedder, vector_store, retriever)

@app.post("/api/v1/rag/retrieve")
async def retrieve(request: RetrieveRequest) -> RetrieveResponse:
    """Retrieve relevant context for a query."""
    try:
        # Resolve document_id if document_external_id provided
        document_id = request.document_id
        if request.document_external_id and not document_id:
            from ai.rag.vector_store import resolve_document_db_id
            document_id = resolve_document_db_id(
                vector_store.connection,
                request.document_external_id
            )
        
        # Retrieve context
        response = rag_service.retrieve_context(
            query=request.query,
            document_id=document_id,
            top_k=request.top_k
        )
        
        return RetrieveResponse(**response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/rag/ingest")
async def ingest(request: IngestRequest) -> IngestResponse:
    """Ingest document pages into RAG system."""
    try:
        result = load_and_ingest(
            document_pages_path=request.document_pages_path,
            document_external_id=request.document_external_id,
            chunk_size=request.chunk_size,
            overlap=request.overlap,
            skip_duplicates=request.skip_duplicates
        )
        return IngestResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/rag/health")
async def health() -> HealthResponse:
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        database_connected=getattr(vector_store, "connection", None) is not None,
        embedding_model_loaded=embedder is not None,
        version="1.0.0"
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

## Rate Limiting

### Default Limits
- **Retrieve**: 100 requests/minute
- **Ingest**: 10 requests/minute
- **Health**: 1000 requests/minute

### Rate Limit Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1626424200
```

## Pagination

### Document List Pagination
- **Default limit**: 50
- **Maximum limit**: 100
- **Offset**: 0-based

### Example
```
GET /api/v1/rag/documents?limit=20&offset=0
```

## Versioning

### API Versioning
- **Current Version**: v1
- **Version Format**: /api/v{version}/{endpoint}
- **Backward Compatibility**: Maintained for 1 major version

### Version Header
```
X-API-Version: 1.0.0
```

## Security

### Authentication (To Be Implemented)
- **Type**: API Key or JWT
- **Header**: `Authorization: Bearer <token>`
- **Scope**: read (retrieve), write (ingest)

### CORS
- **Allowed Origins**: To be configured
- **Allowed Methods**: GET, POST
- **Allowed Headers**: Authorization, Content-Type

## Monitoring

### Metrics to Track
- Request count by endpoint
- Average latency by endpoint
- Error rate by endpoint
- Database connection status
- Embedding generation time

### Logging
- **Level**: INFO
- **Format**: JSON
- **Fields**: timestamp, level, endpoint, status_code, latency_ms

## Testing

### Example cURL Commands

#### Retrieve
```bash
curl -X POST http://localhost:8000/api/v1/rag/retrieve \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is the DataFlow pipeline?",
    "document_external_id": "doc_dataflow_technical_report",
    "top_k": 5
  }'
```

#### Ingest
```bash
curl -X POST http://localhost:8000/api/v1/rag/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "document_pages_path": "outputs/rag_handoff/week7_document_pages_db_enriched.jsonl",
    "document_external_id": "doc_dataflow_technical_report"
  }'
```

#### Health
```bash
curl http://localhost:8000/api/v1/rag/health
```

## Week 8/9 Integration

### For Phi/Hung
- **Base URL**: Will be provided by Lap
- **Authentication**: Will be configured
- **UI Integration**: Use /retrieve endpoint for RAG queries
- **Response Format**: Matches lap_rag_response_real.json

### For Duy
- **Ingestion**: Use /ingest endpoint to load documents
- **Document Pages**: Ensure document_pages.jsonl format matches expectations
- **Document External ID**: Use consistent identifiers

### For Phat
- **Database**: Ensure DATABASE_URL is configured
- **Schema**: Ensure schema_v4 tables exist
- **Permissions**: Ensure API has database access

## Status

**Status**: Contract defined, implementation pending

**Implementation**: Week 8/9 staging MVP

**Testing**: Pending FastAPI implementation

**Documentation**: Complete

## Next Steps

1. Implement FastAPI application
2. Add authentication middleware
3. Add rate limiting
4. Add monitoring and logging
5. Deploy to staging environment
6. Test with Phi/Hung UI
7. Test with Duy ingestion workflow
