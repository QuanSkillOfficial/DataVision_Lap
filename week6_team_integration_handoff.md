# Week 6 Team Integration Handoff

## Owner
Lap

## Role
RAG / Vector Search Module Owner

## Purpose
Define what Lap provides to each team member, what Lap needs from each team member, and all Week 6 deliverables required to complete platform integration.

## Week 6 Main Goal
The RAG system is service-ready after Week 5. The next step is to connect it into the full platform workflow so every module works together, not just separately.

This week should focus on:
- normalize
- integrate
- insert
- fixture
- filter
- feedback
- retrain
- test

Lap's RAG service is the retrieval and evidence layer of the platform. The goal is to make retrieval outputs usable by:
- Duy ingestion handoff package
- Phat pgvector storage and query logs
- Phi/Hung UI and citation display
- Tuong document type filtering metadata

## What Lap Provides

### 1. For Phat — pgvector storage and query logging
Lap provides chunked document vectors and retrieval logs for Phat to store in PostgreSQL and query through pgvector.

Key files:
- ai/rag/load_document_pages_to_pgvector.py
- ai/rag/vector_store.py
- ai/rag/retriever.py
- ai/rag/rag_pipeline.py
- ai/week6_rag_to_schema_v4_mapping.md

### 2. For Phi/Hung — RAG UI fixture and citations
Lap provides a real RAG response fixture so Phi/Hung can build the chatbot, citations, and retrieval preview experience.

Key files:
- outputs/ui_fixtures/lap_rag_response_real.json
- ai/rag/notebooks/week6_real_pgvector_rag_demo.ipynb
- screenshots/week6_pgvector_retrieval_result.png

### 3. For Tuong — RAG metadata filtering support
Lap provides document type metadata and filtering rules so Tuong's predictions can be used safely in retrieval filtering.

Key files:
- outputs/rag_metadata/document_type_filter_payload.json
- docs/prediction_to_rag_filtering_contract.md

### 4. For Duy — RAG handoff validation
Lap provides feedback on whether Duy's document handoff package is truly RAG-ready.

Key files:
- ai/week6_duy_dataflow_ingestion_result.md
- outputs/rag_handoff/document_pages.jsonl
- outputs/rag_handoff/pdf_metadata.json
- outputs/rag_handoff/rag_handoff_summary.md

## What Lap Needs From Others

### From Duy
Lap needs:
- real document_pages.jsonl
- pdf_metadata.json
- document_external_id
- file_name
- page_number
- text
- character_count
- is_empty
- rag_handoff_summary.md

### From Phat
Lap needs:
- schema_v4.sql
- database connection details
- documents.document_external_id field
- document_chunks table definition
- rag_query_logs table definition
- pgvector extension enabled
- vector index available
- validation queries

### From Tuong
Lap needs:
- document_type label list
- prediction confidence and status rules
- metadata field name for document_type
- whether filtering should use only accepted predictions

### From Phi/Hung
Lap needs:
- final RAG UI contract
- citation display format
- retrieved context preview length
- similarity score formatting
- no-answer UI state
- report evidence field requirements

## Week 6 Tasks for Lap

### Task 1: Fix package imports and make tests pass
Fix imports in:
- ai/rag/rag_pipeline.py
- ai/rag/test_embedding.py

Change:
- from chunker import Chunker

To:
- from .chunker import Chunker

Add:
- ai/__init__.py

Then run:
- pytest ai/ai_tests/

Expected result:
- all tests passing

### Task 2: Fix result contract consistency
Update vector_store.py so both in-memory and pgvector results return:
- chunk_id
- document_id
- chunk_text
- page_number
- metadata
- score
- similarity_score

In search_in_memory(), add:
- "page_number": chunk_data.get("metadata", {}).get("page_number")

For UI output, convert:
- score → similarity_score

This helps Phi/Hung directly display RAG results.

### Task 3: Work with Phat on schema_v4
Lap should not create production tables independently.

Change the pgvector logic to:
- validate schema exists
- insert into existing document_chunks
- search existing document_chunks
- log into existing rag_query_logs

Create:
- ai/week6_rag_to_schema_v4_mapping.md

Confirm with Phat:
- documents.document_external_id
- documents.id
- document_chunks.chunk_id
- document_chunks.document_id
- document_chunks.embedding vector(384)
- document_chunks.chunk_metadata
- rag_query_logs fields

### Task 4: Implement document external ID mapping
Create function:
- def resolve_document_db_id(conn, document_external_id: str) -> int:
-     pass

Expected behavior:
- Input: doc_dataflow_technical_report
- Lookup: SELECT id FROM documents WHERE document_external_id = %s
- Output: integer documents.id

If missing:
- return a clear error
- or create the document only if Phat and Duy agree

Do not insert string document IDs into integer foreign key columns.

### Task 5: Use Duy's real RAG handoff package
Use Duy's Week 6 output:
- outputs/rag_handoff/document_pages.jsonl
- outputs/rag_handoff/pdf_metadata.json
- outputs/rag_handoff/rag_handoff_summary.md

Create:
- ai/week6_duy_dataflow_ingestion_result.md

Fill real values:
- pages loaded
- non-empty pages
- empty pages skipped
- total characters
- chunks created
- average chunks per page
- embeddings generated
- vectors inserted
- insertion time

No TBD values.

### Task 6: Create real pgvector loader script
Create:
- ai/rag/load_document_pages_to_pgvector.py

Flow:
1. Load Duy document_pages.jsonl
2. Validate pages
3. Convert pages to chunks
4. Resolve document_external_id to documents.id
5. Generate embeddings
6. Insert chunks into Phat document_chunks
7. Print inserted count

Expected command:
- python -m ai.rag.load_document_pages_to_pgvector --document-pages outputs/rag_handoff/document_pages.jsonl --document-external-id doc_dataflow_technical_report

### Task 7: Create executed Week 6 pgvector demo
Create:
- ai/rag/notebooks/week6_real_pgvector_rag_demo.ipynb

Or a script plus screenshot.

It must show real outputs:
- database connected
- pages loaded
- chunks created
- embeddings generated
- chunks inserted
- top-5 results retrieved
- chunk_id
- page_number
- similarity_score
- citation output

Also save:
- screenshots/week6_pgvector_retrieval_result.png

### Task 8: Run real retrieval evaluation
Create:
- ai/rag/evaluation/week6_retrieval_test_cases_dataflow.csv
- ai/rag/evaluation/week6_retrieval_eval_results.md

Use at least 15–20 real questions.

Track:
- query
- expected_page
- top1_page
- top3_pages
- retrieved_chunk_id
- similarity_score
- hit_at_1
- hit_at_3
- hit_at_5
- comment

Report:
- Hit@1
- Hit@3
- Hit@5
- MRR
- average similarity
- failed query analysis

### Task 9: Add actual RAG query logging integration
Currently log_rag_query() builds a payload. Week 6 should add actual DB insert support.

Create:
- def insert_rag_query_log(conn, log_payload):
-     pass

It should insert into Phat's rag_query_logs.

Expected payload:
{
  "document_id": 1,
  "user_query": "What is the data pipeline?",
  "retrieved_chunk_ids": ["doc_dataflow_page_4_chunk_000"],
  "retrieval_scores": [0.84],
  "generated_response": null,
  "answer_confidence": 0.84,
  "latency_ms": 320,
  "model_name": "all-MiniLM-L6-v2"
}

### Task 10: Prepare Phi/Hung-ready RAG response fixture
Create:
- outputs/ui_fixtures/lap_rag_response_real.json

It should match Phi/Hung's UI contract:
{
  "question": "What is the DataFlow pipeline?",
  "answer": null,
  "retrieved_context": [
    {
      "chunk_id": "doc_dataflow_technical_report_page_4_chunk_000",
      "document_id": 1,
      "file_name": "DataFlow_Technical_Report.pdf",
      "page_number": 4,
      "chunk_text": "...",
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
  "status": "retrieval_only",
  "model": "all-MiniLM-L6-v2"
}

## Lap's Week 6 Deliverables Checklist

- [ ] Fixed ai/rag/rag_pipeline.py with package-safe imports
- [ ] Added ai/__init__.py
- [ ] Updated vector_store.py with consistent result contract
- [ ] Updated retriever.py if needed
- [ ] Created ai/week6_rag_to_schema_v4_mapping.md
- [ ] Created ai/rag/load_document_pages_to_pgvector.py
- [ ] Created ai/rag/notebooks/week6_real_pgvector_rag_demo.ipynb executed
- [ ] Created ai/week6_duy_dataflow_ingestion_result.md with real values
- [ ] Created ai/rag/evaluation/week6_retrieval_test_cases_dataflow.csv
- [ ] Created ai/rag/evaluation/week6_retrieval_eval_results.md
- [ ] Implemented insert_rag_query_log()
- [ ] Created outputs/ui_fixtures/lap_rag_response_real.json
- [ ] Created screenshots/week6_pgvector_retrieval_result.png
- [ ] Captured pytest results showing tests pass
- [ ] Prepared WEEK_6_SUMMARY.md

## Week 6 Friday Demo for Lap

Lap should demo:
1. Run pytest and show all tests pass.
2. Load Duy's real document_pages.jsonl.
3. Show page count and character count.
4. Convert pages into page-aware chunks.
5. Show chunk IDs with page numbers.
6. Generate 384-dimensional embeddings.
7. Resolve document_external_id to Phat documents.id.
8. Insert chunks into Phat document_chunks.
9. Run pgvector similarity search.
10. Show top-5 retrieved chunks.
11. Show file name, page number, chunk ID, and similarity score.
12. Show citation output for Phi/Hung.
13. Insert or show RAG query log payload for Phat.
14. Show retrieval evaluation metrics.

## Key Demo Story
The RAG system is now actually connected:
Duy extracted the document, Phat stored the vectors, Lap retrieved evidence, and Phi/Hung can display citations.

## How Other Team Members Depend on Lap's Week 6 Work

### Duy depends on Lap
Duy needs Lap to confirm that the PDF output is truly RAG-ready.

### Phat depends on Lap
Phat needs the final pgvector insert format, document_chunks column requirements, embedding dimension = 384, chunk_id format, document_external_id mapping, RAG similarity query, and rag_query_logs payload.

### Tuong depends on Lap
Tuong's document type prediction can later improve RAG filtering. Lap should prepare metadata filters for document_type, prediction_status, source_name, and document_external_id.

### Phi/Hung depend on Lap
Phi/Hung need Lap's response to power the chatbot page, report evidence, citation cards, retrieved context preview, and similarity score badges.

## Final Manager Summary for Lap
Lap has made useful Week 4-5 progress, especially in service design, schema mapping, citation handling, and RAG logging payloads.

But the most important integration proof is still missing. Week 6 mission is to prove the real RAG pipeline:
Duy document_pages.jsonl → Lap chunks and embeddings → Phat pgvector document_chunks → Lap retrieval → Phi/Hung citation-ready response.

Lap should focus on:
- passing tests
- real database insertion
- real retrieval
- real evaluation
- real UI fixture

That is the correct Week 6 direction.
