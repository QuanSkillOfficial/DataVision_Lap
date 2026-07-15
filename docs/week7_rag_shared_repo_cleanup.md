# Week 7 RAG Shared Repo Cleanup

**Author:** Lap (RAG / Vector Search Module Owner)
**Week:** 7
**Date:** July 2026

## Purpose

Clean and prepare the RAG module for the shared GitHub repository to ensure a clean, maintainable structure for the team.

## Cleanup Actions Taken

### Files Removed

The following old/duplicate files were removed to avoid confusion:

1. **ai/rag/ai/** - Nested duplicate folder structure
   - Removed entire `ai/rag/ai/` directory
   - Contained duplicate evaluation files from Week 3

2. **ai/rag/test_embedding.py** - Old standalone test script
   - Replaced by proper pytest tests in `ai/ai_tests/`

3. **ai/rag/embedding_test_notes.md** - Week 1 documentation
   - Archived as historical context no longer needed for active development

4. **ai/rag/rag_architecture_understanding.md** - Week 3 architecture notes
   - Superseded by current implementation

5. **ai/rag/rag_module_plan.md** - Week 3 planning document
   - Outdated planning document

6. **ai/rag/summary.md** - Week 3 summary
   - Outdated summary document

### Directories Created

1. **ai/rag/scripts/** - For executable scripts
   - Will contain smoke test scripts and utility scripts

2. **docs/** - For project-wide documentation
   - Will contain integration documentation, contracts, and runbooks

3. **outputs/ui_fixtures/** - For UI test fixtures
   - Will contain RAG response fixtures for Phi/Hung

4. **outputs/rag/** - For RAG-specific outputs
   - Will contain query results, insertion summaries, and evaluation results

## Current Active RAG Files

### Core RAG Module (ai/rag/)

- `__init__.py` - Package initialization
- `chunker.py` - Document chunking logic
- `embedder.py` - Embedding generation using sentence-transformers
- `vector_store.py` - Vector storage (in-memory and pgvector)
- `retriever.py` - Similarity search and retrieval
- `rag_pipeline.py` - End-to-end RAG pipeline
- `rag_service.py` - Service layer for RAG operations
- `document_loader.py` - Document loading and validation
- `load_document_pages_to_pgvector.py` - pgvector insertion script
- `answer_generator.py` - Answer generation (optional feature)

### Documentation (ai/rag/docs/)

- `chunking_strategy.md` - Chunking approach documentation
- `document_pages_to_chunks_contract.md` - Data contract for chunking
- `embedding_model_notes.md` - Embedding model selection notes
- `pgvector_handoff_requirements.md` - pgvector integration requirements
- `pgvector_integration_notes.md` - pgvector technical notes
- `rag_query_log_contract.md` - Query logging data contract
- `rag_response_contract.md` - RAG response format contract
- `testing_guide.md` - Testing guidelines

### Evaluation (ai/rag/evaluation/)

- `retrieval_eval_results_week3.md` - Week 3 evaluation results (archived)
- `retrieval_test_cases_completed.csv` - Week 3 test cases (archived)
- `week6_retrieval_eval_results.md` - Week 6 evaluation results
- `week6_retrieval_test_cases_dataflow.csv` - Week 6 DataFlow test cases

### Notebooks (ai/rag/notebooks/)

- `week6_real_pgvector_rag_demo.ipynb` - Week 6 pgvector demo notebook

### Tests (ai/ai_tests/)

- `test_chunker.py` - Chunker unit tests
- `test_citations.py` - Citation formatting tests
- `test_document_loader.py` - Document loader tests
- `test_prediction_contract.py` - Prediction contract tests
- `test_rag_response_contract.py` - RAG response contract tests
- `test_retriever.py` - Retriever tests
- `test_vector_store_pgvector_connection.py` - pgvector connection tests

### Requirements

- `requirements.txt` - RAG-specific dependencies

## Clean Folder Structure

```
datavision-platform/
├── ai/
│   ├── __init__.py
│   ├── rag/
│   │   ├── __init__.py
│   │   ├── chunker.py
│   │   ├── embedder.py
│   │   ├── vector_store.py
│   │   ├── retriever.py
│   │   ├── rag_pipeline.py
│   │   ├── rag_service.py
│   │   ├── document_loader.py
│   │   ├── load_document_pages_to_pgvector.py
│   │   ├── answer_generator.py
│   │   ├── scripts/
│   │   │   ├── week7_pgvector_smoke_test.py
│   │   │   └── week7_rag_ci_smoke_test.py
│   │   ├── docs/
│   │   │   ├── chunking_strategy.md
│   │   │   ├── document_pages_to_chunks_contract.md
│   │   │   ├── embedding_model_notes.md
│   │   │   ├── pgvector_handoff_requirements.md
│   │   │   ├── pgvector_integration_notes.md
│   │   │   ├── rag_query_log_contract.md
│   │   │   ├── rag_response_contract.md
│   │   │   └── testing_guide.md
│   │   ├── evaluation/
│   │   │   ├── week6_retrieval_eval_results.md
│   │   │   └── week6_retrieval_test_cases_dataflow.csv
│   │   └── notebooks/
│   │       └── week6_real_pgvector_rag_demo.ipynb
│   ├── ai_tests/
│   │   ├── test_chunker.py
│   │   ├── test_citations.py
│   │   ├── test_document_loader.py
│   │   ├── test_prediction_contract.py
│   │   ├── test_rag_response_contract.py
│   │   ├── test_retriever.py
│   │   ├── test_vector_store_pgvector_connection.py
│   │   └── fakes.py
│   └── WEEK_6_SUMMARY.md
├── docs/
│   ├── week7_rag_shared_repo_cleanup.md
│   ├── week7_duy_to_lap_rag_handoff_validation.md
│   ├── week7_lap_phat_pgvector_integration_result.md
│   ├── week7_rag_query_log_insert_result.md
│   ├── week7_tuong_to_lap_safe_rag_filtering.md
│   ├── week7_lap_ci_commands.md
│   ├── week7_rag_api_contract.md
│   ├── week7_rag_environment_requirements.md
│   └── week7_rag_runbook.md
├── outputs/
│   ├── ui_fixtures/
│   │   └── lap_rag_response_real.json
│   └── rag/
│       ├── week7_chunk_insert_summary.json
│       ├── week7_pgvector_insert_result.json
│       ├── week7_pgvector_search_result.json
│       └── week7_rag_query_log_payload.json
└── sql/
    └── (Phat's SQL files)
```

## Commands to Run RAG Tests

### Run All RAG Tests
```bash
pytest ai/ai_tests/
```

### Run Specific Test File
```bash
pytest ai/ai_tests/test_chunker.py
```

### Run with Verbose Output
```bash
pytest ai/ai_tests/ -v
```

### Run with Coverage
```bash
pytest ai/ai_tests/ --cov=ai/rag --cov-report=html
```

## Validation

After cleanup, the following validations were performed:

1. ✅ No duplicate folder structures remain
2. ✅ All active RAG files are properly organized
3. ✅ Test files are in the correct location (ai/ai_tests/)
4. ✅ Documentation is organized in ai/rag/docs/
5. ✅ Scripts directory created for executable scripts
6. ✅ Output directories created for fixtures and results
7. ✅ Old/archived files removed to avoid confusion

## Next Steps

1. Create `ai/ai_tests/fakes.py` for CI-safe testing
2. Update test suite to use FakeEmbedder for CI
3. Ensure all tests pass with fake dependencies
4. Create smoke test scripts in `ai/rag/scripts/`
5. Generate real UI fixtures for Phi/Hung

## Notes for Team

- The RAG module is now clean and ready for the shared GitHub repository
- All old Week 1-3 artifacts have been removed or archived
- The structure follows the agreed-upon shared repo layout
- Tests are properly separated from production code
- Documentation is organized for easy reference
