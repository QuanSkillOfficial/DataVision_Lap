# Week 7 Duy to Lap RAG Handoff Validation

**Author:** Lap (RAG / Vector Search Module Owner)
**Week:** 7
**Date:** July 2026

## Purpose

Validate Duy's Week 7 RAG handoff to ensure document_pages.jsonl is ready for RAG processing and pgvector insertion.

## Expected Input from Duy

Lap expects the following files from Duy's Week 7 output:

1. **outputs/rag_handoff/week7_document_pages_db_enriched.jsonl**
   - DB-enriched document pages with document_db_id
   - Contains extracted text, page numbers, metadata

2. **outputs/rag_handoff/week7_rag_handoff_manifest.json**
   - Manifest file with ingestion metadata
   - Contains document_external_id, source_id, ingestion_run_id

3. **outputs/rag_handoff/pdf_metadata.json**
   - PDF metadata including file_name, page_count
   - Contains document_external_id mapping

## Validation Requirements

### Required Fields in document_pages.jsonl

Each page record must contain:

- **document_external_id** (string): Unique document identifier
  - Expected: `doc_dataflow_technical_report`
  
- **document_db_id** (integer, optional): Database document ID if DB loading complete
  - Expected: `1` or actual database ID
  
- **source_id** (string, optional): Source system identifier
  - Expected: Source system ID if available
  
- **file_name** (string): Original PDF filename
  - Expected: `DataFlow_Technical_Report.pdf`
  
- **page_number** (integer): Page number (1-indexed)
  - Expected: `1` to `page_count`
  
- **text** (string): Extracted text content
  - Expected: Non-empty for non-empty pages
  
- **char_count** (integer): Character count
  - Expected: `len(text)`
  
- **word_count** (integer): Word count
  - Expected: Word count of text
  
- **is_empty** (boolean): Whether page is empty
  - Expected: `true` if text is empty, `false` otherwise
  
- **ingestion_run_id** (string): Ingestion run identifier
  - Expected: UUID or run identifier

### Expected DataFlow Values

For the DataFlow Technical Report:

- **document_external_id**: `doc_dataflow_technical_report`
- **file_name**: `DataFlow_Technical_Report.pdf`
- **page_count**: `36`
- **non_empty_pages**: `36` (or actual count)
- **document_db_id**: `1` (if DB loaded)

## Validation Process

### Step 1: Load and Validate JSONL Structure

```python
from ai.rag.document_loader import DocumentLoader

pages = DocumentLoader.load_document_pages_jsonl(
    "outputs/rag_handoff/week7_document_pages_db_enriched.jsonl"
)
```

### Step 2: Validate Required Fields

```python
required_fields = [
    "document_external_id",
    "file_name",
    "page_number",
    "text",
    "char_count",
    "word_count",
    "is_empty",
    "ingestion_run_id"
]

for page in pages:
    for field in required_fields:
        assert field in page, f"Missing required field: {field}"
```

### Step 3: Validate Data Consistency

```python
# Validate char_count matches text length
for page in pages:
    assert page["char_count"] == len(page["text"]), \
        f"char_count mismatch for page {page['page_number']}"

# Validate is_empty flag
for page in pages:
    assert page["is_empty"] == (len(page["text"]) == 0), \
        f"is_empty flag incorrect for page {page['page_number']}"
```

### Step 4: Validate Page Sequence

```python
page_numbers = [page["page_number"] for page in pages]
assert page_numbers == sorted(page_numbers), "Pages not in sequence"
assert page_numbers[0] == 1, "First page should be 1"
```

### Step 5: Validate Document Consistency

```python
# All pages should have same document_external_id
doc_ids = {page["document_external_id"] for page in pages}
assert len(doc_ids) == 1, f"Multiple document IDs found: {doc_ids}"

# All pages should have same file_name
file_names = {page["file_name"] for page in pages}
assert len(file_names) == 1, f"Multiple file names found: {file_names}"
```

## Validation Results Template

### Document Summary

- **Document External ID**: `doc_dataflow_technical_report`
- **Document DB ID**: `1` (if available)
- **Source ID**: `source_001` (if available)
- **File Name**: `DataFlow_Technical_Report.pdf`
- **Ingestion Run ID**: `run_uuid_here`

### Page Statistics

- **Total Pages**: `36`
- **Empty Pages**: `0`
- **Non-Empty Pages**: `36`
- **Total Characters**: `15,234` (example)
- **Total Words**: `2,456` (example)
- **Average Characters per Page**: `423` (example)

### Chunking Estimates

- **Expected Chunks** (chunk_size=500, overlap=50): `~35 chunks`
- **Expected Embeddings**: `~35 embeddings`
- **Embedding Dimension**: `384`

### Issues Found

- **None** (if validation passes)
- **Issue description** (if validation fails)

### Fixes Needed from Duy

- **None** (if validation passes)
- **Specific fix required** (if validation fails)

## Sample Validation Output

```json
{
  "validation_status": "passed",
  "document_external_id": "doc_dataflow_technical_report",
  "document_db_id": 1,
  "source_id": "dataflow_source_001",
  "file_name": "DataFlow_Technical_Report.pdf",
  "ingestion_run_id": "ingestion_run_2026_07_16_001",
  "page_statistics": {
    "total_pages": 36,
    "empty_pages": 0,
    "non_empty_pages": 36,
    "total_characters": 15234,
    "total_words": 2456,
    "avg_chars_per_page": 423
  },
  "chunking_estimates": {
    "expected_chunks": 35,
    "expected_embeddings": 35,
    "embedding_dimension": 384
  },
  "issues_found": [],
  "fixes_needed": []
}
```

## Next Steps After Validation

### If Validation Passes:

1. Proceed with chunking using validated pages
2. Generate embeddings using sentence-transformers
3. Resolve document_external_id to document_db_id
4. Insert chunks into Phat's document_chunks table
5. Run pgvector similarity search
6. Create RAG response fixture for Phi/Hung

### If Validation Fails:

1. Document specific issues found
2. Request fixes from Duy
3. Re-run validation after fixes
4. Only proceed after validation passes

## Integration with Phat's Database

### Document ID Resolution

Lap will resolve document_external_id to Phat's documents.id:

```python
from ai.rag.vector_store import resolve_document_db_id

document_db_id = resolve_document_db_id(
    connection=phat_connection,
    document_external_id="doc_dataflow_technical_report"
)
# Expected: document_db_id = 1
```

### Chunk Insertion

Lap will insert chunks into Phat's document_chunks table:

```python
# Table: document_chunks
# Columns: chunk_id, document_id, chunk_text, embedding, chunk_metadata, page_number

for chunk in chunks:
    cursor.execute("""
        INSERT INTO document_chunks 
        (chunk_id, document_id, chunk_text, embedding, chunk_metadata, page_number)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (
        chunk["chunk_id"],
        document_db_id,
        chunk["chunk_text"],
        chunk["embedding"],
        json.dumps(chunk["metadata"]),
        chunk["metadata"]["page_number"]
    ))
```

## Handoff Checklist

- [ ] Received week7_document_pages_db_enriched.jsonl
- [ ] Received week7_rag_handoff_manifest.json
- [ ] Received pdf_metadata.json
- [ ] Validated JSONL structure
- [ ] Validated all required fields present
- [ ] Validated data consistency
- [ ] Validated page sequence
- [ ] Validated document consistency
- [ ] Confirmed document_external_id matches expected
- [ ] Confirmed file_name matches expected
- [ ] Confirmed page_count matches expected
- [ ] Documented any issues found
- [ ] Requested fixes from Duy if needed
- [ ] Ready to proceed with chunking and embedding

## Notes for Duy

1. **Field Names**: Use exact field names specified above
2. **Data Types**: Ensure correct data types (integers, booleans, strings)
3. **Empty Pages**: Mark truly empty pages with is_empty=true
4. **Character Counts**: Ensure char_count matches actual text length
5. **Document ID**: Use consistent document_external_id across all pages
6. **Page Numbers**: Use 1-indexed page numbers starting from 1
7. **Ingestion Run ID**: Include unique identifier for tracking

## Notes for Phat

1. **Document ID**: Expect document_external_id = "doc_dataflow_technical_report"
2. **Document DB ID**: Expect documents.id = 1 for this document
3. **Chunk Count**: Expect ~35 chunks for 36-page document
4. **Embedding Dimension**: All embeddings will be 384-dimensional
5. **Insertion**: Lap will insert into existing document_chunks table
6. **Query Logs**: Lap will log RAG queries to rag_query_logs table

## Validation Status

**Status**: Pending Duy's Week 7 handoff delivery

**Last Updated**: July 2026

**Next Review**: After receiving Duy's Week 7 output
