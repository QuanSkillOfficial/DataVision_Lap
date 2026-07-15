# Week 7 RAG Runbook

**Author:** Lap (RAG / Vector Search Module Owner)
**Week:** 7
**Date:** July 2026

## Purpose

Provide a comprehensive runbook for the team to operate, troubleshoot, and maintain the RAG module.

## Quick Start

### For Duy (Document Processing)

```bash
# 1. Install dependencies
pip install pytest numpy scikit-learn sentence-transformers torch psycopg2-binary
pip install -e .

# 2. Run tests
python -m pytest ai/ai_tests/test_document_loader.py -v

# 3. Ingest document pages
python ai/rag/load_document_pages_to_pgvector.py \
    --document-pages outputs/rag_handoff/week7_document_pages_db_enriched.jsonl \
    --document-external-id doc_dataflow_technical_report \
    --connection-string "$DATABASE_URL" \
    --output-result outputs/rag/week7_pgvector_insert_result.json
```

### For Phat (Database Operations)

```bash
# 1. Set database URL
export DATABASE_URL="postgresql://user:password@localhost:5432/datavision"

# 2. Validate schema
psql $DATABASE_URL -c "SELECT to_regclass('public.document_chunks');"

# 3. Run pgvector tests
python -m pytest ai/ai_tests/test_vector_store_pgvector_connection.py -v

# 4. Run smoke test
python ai/rag/scripts/week7_pgvector_smoke_test.py \
    --query "What is the DataFlow pipeline?" \
    --document-external-id doc_dataflow_technical_report \
    --top-k 5
```

### For Phi/Hung (UI Integration)

```bash
# 1. Run UI contract tests
python -m pytest ai/ai_tests/test_rag_response_contract.py ai/ai_tests/test_citations.py -v

# 2. Validate UI fixture
python -c "
import json
with open('outputs/ui_fixtures/lap_rag_response_real.json') as f:
    data = json.load(f)
required = ['question', 'answer', 'status', 'retrieved_context', 'citations', 'metadata']
for field in required:
    assert field in data, f'Missing field: {field}'
print('✓ UI fixture valid')
"
```

### For Tuong (Document Type Predictions)

```bash
# 1. Review safe filtering rules
cat docs/week7_tuong_to_lap_safe_rag_filtering.md

# 2. Coordinate on confidence thresholds
# Contact Lap to confirm 0.80 threshold is appropriate
```

## Daily Operations

### Running Tests

#### CI-Safe Tests (No Database Required)

```bash
# Run all unit tests
python -m pytest ai/ai_tests/ -v

# Run CI smoke test
python ai/rag/scripts/week7_rag_ci_smoke_test.py
```

#### Integration Tests (Database Required)

```bash
# Set database URL
export DATABASE_URL="postgresql://user:password@localhost:5432/datavision"

# Run pgvector connection tests
python -m pytest ai/ai_tests/test_vector_store_pgvector_connection.py -v

# Run pgvector smoke test
python ai/rag/scripts/week7_pgvector_smoke_test.py \
    --query "What is the DataFlow pipeline?" \
    --document-external-id doc_dataflow_technical_report \
    --top-k 5
```

### Ingesting Documents

#### Step 1: Validate Document Pages

```bash
# Check document_pages.jsonl format
python -c "
import json
with open('outputs/rag_handoff/week7_document_pages_db_enriched.jsonl') as f:
    for i, line in enumerate(f):
        page = json.loads(line)
        print(f'Page {i+1}: {page.get(\"page_number\")}, chars: {page.get(\"char_count\")}')
"
```

#### Step 2: Ingest into pgvector

```bash
python ai/rag/load_document_pages_to_pgvector.py \
    --document-pages outputs/rag_handoff/week7_document_pages_db_enriched.jsonl \
    --document-external-id doc_dataflow_technical_report \
    --chunk-size 512 \
    --overlap 50 \
    --skip-duplicates \
    --connection-string "$DATABASE_URL" \
    --output-result outputs/rag/week7_pgvector_insert_result.json
```

#### Step 3: Verify Insertion

```bash
# Check chunk count
psql $DATABASE_URL -c "SELECT COUNT(*) FROM document_chunks WHERE document_id = 1;"

# Check sample chunks
psql $DATABASE_URL -c "SELECT chunk_id, page_number, LEFT(chunk_text, 50) FROM document_chunks LIMIT 5;"
```

### Running Retrieval

#### Using Python Script

```bash
python ai/rag/scripts/week7_pgvector_smoke_test.py \
    --query "What is the DataFlow pipeline?" \
    --document-external-id doc_dataflow_technical_report \
    --top-k 5 \
    --connection-string "$DATABASE_URL" \
    --output-result outputs/rag/week7_retrieval_result.json
```

#### Using Python API

```python
from ai.rag.embedder import Embedder
from ai.rag.vector_store import VectorStore
from ai.rag.retriever import Retriever

embedder = Embedder()
vector_store = VectorStore(use_pgvector=True, connection_string="$DATABASE_URL")
retriever = Retriever(embedder=embedder, vector_store=vector_store, top_k=5)

results = retriever.retrieve("What is the DataFlow pipeline?", document_id=1)
for result in results:
    print(f"Chunk: {result['chunk_id']}, Page: {result['page_number']}, Score: {result['similarity_score']:.3f}")
```

## Troubleshooting

### Common Issues

#### Issue: Tests failing with import errors

**Symptom**: `ModuleNotFoundError: No module named "ai.rag"`

**Solution**:
```bash
# Install package in development mode
pip install -e .
```

#### Issue: Database connection failed

**Symptom**: `RuntimeError: Unable to connect to pgvector`

**Solution**:
```bash
# Check database URL
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL -c "SELECT 1;"

# Check pgvector extension
psql $DATABASE_URL -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"
```

#### Issue: Model download failed

**Symptom**: `OSError: Can't load tokenizer for 'all-MiniLM-L6-v2'`

**Solution**:
```bash
# Set Hugging Face mirror (if in China)
export HF_ENDPOINT=https://hf-mirror.com

# Or pre-download model
python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"
```

#### Issue: Duplicate chunks inserted

**Symptom**: `RuntimeError: Duplicate chunk_id`

**Solution**:
```bash
# Use --skip-duplicates flag
python ai/rag/load_document_pages_to_pgvector.py \
    --document-pages outputs/rag_handoff/week7_document_pages_db_enriched.jsonl \
    --document-external-id doc_dataflow_technical_report \
    --skip-duplicates \
    --connection-string "$DATABASE_URL"
```

#### Issue: Low retrieval quality

**Symptom**: Retrieved chunks not relevant to query

**Solution**:
```bash
# Check embedding dimension
python -c "from ai.rag.embedder import Embedder; print(Embedder().get_embedding_dimension())"

# Check chunk quality
psql $DATABASE_URL -c "SELECT chunk_id, LENGTH(chunk_text) FROM document_chunks ORDER BY LENGTH(chunk_text) DESC LIMIT 5;"

# Try different chunk_size
python ai/rag/load_document_pages_to_pgvector.py \
    --document-pages outputs/rag_handoff/week7_document_pages_db_enriched.jsonl \
    --document-external-id doc_dataflow_technical_report \
    --chunk-size 256 \
    --overlap 25 \
    --connection-string "$DATABASE_URL"
```

### Debugging Steps

#### Enable Debug Logging

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

#### Check Vector Store State

```python
from ai.rag.vector_store import VectorStore

vector_store = VectorStore(use_pgvector=True, connection_string="$DATABASE_URL")
print(f"Connected: {vector_store.connection is not None}")
print(f"Use pgvector: {vector_store.use_pgvector}")
```

#### Check Embedder State

```python
from ai.rag.embedder import Embedder

embedder = Embedder()
print(f"Model: {embedder.model_name}")
print(f"Dimension: {embedder.get_embedding_dimension()}")
```

## Monitoring

### Query Log Monitoring Monitor query logs for performance and quality.

```sql
-- Daily metrics
SELECT 
    DATE(created_at) as query_date,
    COUNT(*) as total_queries,
    AVG(latency_ms) as avg_latency_ms,
    AVG(answer_confidence) as avg_confidence
FROM rag_query_logs
GROUP BY DATE(created_at)
ORDER BY query_date DESC;

-- Top queries
SELECT 
    query_text,
    COUNT(*) as frequency,
    AVG(answer_confidence) as avg_confidence
FROM rag_query_logs
GROUP BY query_text
ORDER BY frequency DESC
LIMIT 10;
```

### Performance Monitoring

#### Latency Targets
- Embedding generation: < 100ms per chunk
- Retrieval: < 50ms for top-5
- End-to-end: < 200ms for retrieval-only

#### Throughput Targets
- Retrieval: 100+ queries/second
- Ingestion: 10+ documents/minute

### Health Checks

```bash
# Database health
psql $DATABASE_URL -c "SELECT 1;"

# pgvector extension
psql $DATABASE_URL -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"

# Schema validation
psql $DATABASE_URL -c "SELECT COUNT(*) FROM document_chunks;"
```

## Maintenance

### Database Maintenance

#### Vacuum and Analyze

```sql
-- Run weekly
VACUUM ANALYZE document_chunks;
VACUUM ANALYZE rag_query_logs;
```

#### Index Maintenance

```sql
-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan 
FROM pg_stat_user_indexes 
WHERE tablename IN ('document_chunks', 'rag_query_logs');
```

### Model Maintenance

#### Model Version Pinning

```txt
# Pin model version in requirements.txt
sentence-transformers==2.2.2
torch==2.0.1
```

#### Model Cache Management

```bash
# Clear model cache
rm -rf ~/.cache/torch/sentence_transformers/

# Pre-download for offline use
python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"
```

### Backup Procedures

#### Database Backup

```bash
# Full backup
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql

# Schema-only backup
pg_dump --schema-only $DATABASE_URL > schema_backup.sql
```

#### Document Backup

```bash
# Backup document_pages.jsonl
cp outputs/rag_handoff/week7_document_pages_db_enriched.jsonl \
   backups/week7_document_pages_db_enriched_$(date +%Y%m%d).jsonl
```

## Emergency Procedures

### Database Connection Lost

#### Symptoms
- `RuntimeError: Unable to connect to pgvector`
- Connection timeout errors

#### Recovery Steps
1. Check database status: `psql $DATABASE_URL -c "SELECT 1;"`
2. Check network connectivity
3. Restart application
4. If persistent, contact Phat

### Model Loading Failed

#### Symptoms
- `OSError: Can't load tokenizer`
- Model download errors

#### Recovery Steps
1. Check internet connection
2. Clear model cache: `rm -rf ~/.cache/torch/sentence_transformers/`
3. Redownload model: `python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"`
4. If persistent, use cached model backup

### Poor Retrieval Quality

#### Symptoms
- Low similarity scores
- Irrelevant chunks retrieved

#### Recovery Steps
1. Check chunk quality: `psql $DATABASE_URL -c "SELECT chunk_id, LENGTH(chunk_text) FROM document_chunks ORDER BY LENGTH(chunk_text) DESC LIMIT 5;"`
2. Re-ingest with different chunk_size
3. Check embedding dimension consistency
4. Run retrieval evaluation: `python ai/rag/scripts/week7_pgvector_smoke_test.py`

### Duplicate Data Issues

#### Symptoms
- `RuntimeError: Duplicate chunk_id`
- Incorrect chunk counts

#### Recovery Steps
1. Identify duplicates: `psql $DATABASE_URL -c "SELECT chunk_id, COUNT(*) FROM document_chunks GROUP BY chunk_id HAVING COUNT(*) > 1;"`
2. Delete duplicates: `psql $DATABASE_URL -c "DELETE FROM document_chunks WHERE ctid NOT IN (SELECT min(ctid) FROM document_chunks GROUP BY chunk_id);"`
3. Re-ingest with --skip-duplicates flag

## Team Coordination

### Duy → Lap Handoff

**When**: After document extraction complete

**Deliverables**:
- `outputs/rag_handoff/week7_document_pages_db_enriched.jsonl`
- `outputs/rag_handoff/week7_rag_handoff_manifest.json`
- `outputs/rag_handoff/pdf_metadata.json`

**Validation**: Lap validates using `week7_duy_to_lap_rag_handoff_validation.md`

### Lap → Phat Integration

**When**: After document pages validated

**Deliverables**:
- Chunks inserted into document_chunks table
- Query logs inserted into rag_query_logs table

**Validation**: Phat validates using `week7_lap_phat_pgvector_integration_result.md`

### Lap → Phi/Hung Handoff

**When**: After retrieval validated

**Deliverables**:
- `outputs/ui_fixtures/lap_rag_response_real.json`
- RAG API contract (Week 8/9)

**Validation**: Phi/Hung validates response format matches UI expectations

### Tuong → Lap Coordination

**When**: Document type predictions available

**Deliverables**:
- Document type predictions with confidence scores
- Safe filtering rules confirmed

**Validation**: Lap validates using `week7_tuong_to_lap_safe_rag_filtering.md`

## Escalation Matrix

### Level 1: Self-Service
- **Issues**: Test failures, import errors, basic troubleshooting
- **Resources**: Runbook, documentation, GitHub issues
- **Resolution**: Self-resolve using runbook

### Level 2: Team Coordination
- **Issues**: Database connection, model download, handoff validation
- **Resources**: Team Slack, direct communication
- **Resolution**: Coordinate with relevant team member

### Level 3: Escalation
- **Issues**: Database schema changes, model version changes, critical failures
- **Resources**: Team lead, architecture review
- **Resolution**: Escalate to team lead for decision

## Documentation References

### Key Documents
- `docs/week7_rag_shared_repo_cleanup.md` - Repository structure
- `docs/week7_duy_to_lap_rag_handoff_validation.md` - Duy handoff validation
- `docs/week7_lap_phat_pgvector_integration_result.md` - Phat integration
- `docs/week7_tuong_to_lap_safe_rag_filtering.md` - Safe filtering rules
- `docs/week7_lap_ci_commands.md` - CI commands
- `docs/week7_rag_api_contract.md` - API contract (Week 8/9)
- `docs/week7_rag_environment_requirements.md` - Environment setup

### Test Files
- `ai/ai_tests/test_chunker.py` - Chunking tests
- `ai/ai_tests/test_document_loader.py` - Document loader tests
- `ai/ai_tests/test_retriever.py` - Retrieval tests
- `ai/ai_tests/test_citations.py` - Citation tests
- `ai/ai_tests/test_rag_response_contract.py` - Response contract tests
- `ai/ai_tests/test_fakes.py` - Fake implementation tests
- `ai/ai_tests/test_vector_store_pgvector_connection.py` - pgvector tests

### Scripts
- `ai/rag/scripts/week7_pgvector_smoke_test.py` - pgvector smoke test
- `ai/rag/scripts/week7_rag_ci_smoke_test.py` - CI smoke test
- `ai/rag/load_document_pages_to_pgvector.py` - Document ingestion

## Week 7 Status

**Status**: Runbook complete

**Implementation**: Ready for team use

**Testing**: Pending team validation

**Documentation**: Complete

## Next Steps

1. Share runbook with team
2. Conduct team walkthrough
3. Validate procedures with real data
4. Update runbook based on feedback
5. Create runbook for Week 8/9 API operations

## Contact Information

### RAG Module Owner
- **Name**: Lap
- **Role**: RAG / Vector Search Module Owner
- **Responsibilities**: RAG pipeline, retrieval, embeddings

### Team Contacts
- **Duy**: Document processing and extraction
- **Phat**: Database and pgvector
- **Phi/Hung**: UI integration
- **Tuong**: Document type predictions

## Appendix

### Quick Reference Commands

```bash
# Run tests
python -m pytest ai/ai_tests/ -v

# Run CI smoke test
python ai/rag/scripts/week7_rag_ci_smoke_test.py

# Ingest document
python ai/rag/load_document_pages_to_pgvector.py \
    --document-pages outputs/rag_handoff/week7_document_pages_db_enriched.jsonl \
    --document-external-id doc_dataflow_technical_report \
    --connection-string "$DATABASE_URL"

# Run retrieval
python ai/rag/scripts/week7_pgvector_smoke_test.py \
    --query "What is the DataFlow pipeline?" \
    --document-external-id doc_dataflow_technical_report \
    --connection-string "$DATABASE_URL"

# Check database
psql $DATABASE_URL -c "SELECT COUNT(*) FROM document_chunks;"
```

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/datavision

# Model (optional)
EMBEDDING_MODEL_PATH=/path/to/model

# API (Week 8/9)
API_HOST=0.0.0.0
API_PORT=8000
```

### File Locations

- **Tests**: `ai/ai_tests/`
- **Scripts**: `ai/rag/scripts/`
- **Documentation**: `docs/`
- **UI Fixtures**: `outputs/ui_fixtures/`
- **RAG Outputs**: `outputs/rag/`
- **Evaluation**: `ai/rag/evaluation/`
