# Week 7 Lap CI Commands

**Author:** Lap (RAG / Vector Search Module Owner)
**Week:** 7
**Date:** July 2026

## Purpose

Provide CI commands for Duy and Phi/Hung to run RAG tests and smoke tests in GitHub Actions.

## CI Test Commands

### For Duy (Document Processing)

#### Run RAG Unit Tests (CI-Safe)

```bash
# Run all RAG unit tests with fake implementations (no database, no model downloads)
python -m pytest ai/ai_tests/ -v --tb=short
```

**Expected Output**: 59 tests passing, 0 failing

**Duration**: ~6 seconds

**Dependencies**: pytest, numpy, scikit-learn

#### Run CI Smoke Test

```bash
# Run fast CI smoke test for GitHub Actions
python ai/rag/scripts/week7_rag_ci_smoke_test.py
```

**Expected Output**: 10 tests passing, status: success

**Duration**: ~2 seconds

**Dependencies**: None (uses fake implementations)

#### Run Document Loader Tests

```bash
# Run document loader specific tests
python -m pytest ai/ai_tests/test_document_loader.py -v
```

**Expected Output**: 8 tests passing

**Duration**: ~1 second

### For Phi/Hung (UI Integration)

#### Run RAG Response Contract Tests

```bash
# Run RAG response contract tests to validate UI fixture format
python -m pytest ai/ai_tests/test_rag_response_contract.py -v
```

**Expected Output**: 6 tests passing

**Duration**: ~1 second

#### Run Citation Tests

```bash
# Run citation format tests
python -m pytest ai/ai_tests/test_citations.py -v
```

**Expected Output**: 4 tests passing

**Duration**: ~1 second

#### Validate UI Fixture Schema

```bash
# Validate lap_rag_response_real.json schema
python -c "
import json
with open('outputs/ui_fixtures/lap_rag_response_real.json') as f:
    data = json.load(f)
required = ['question', 'answer', 'status', 'retrieved_context', 'citations', 'metadata']
for field in required:
    assert field in data, f'Missing field: {field}'
print('✓ UI fixture schema valid')
"
```

**Expected Output**: ✓ UI fixture schema valid

**Duration**: <1 second

### For Phat (Database Integration)

#### Run pgvector Connection Tests

```bash
# Run pgvector connection tests (requires database)
python -m pytest ai/ai_tests/test_vector_store_pgvector_connection.py -v
```

**Expected Output**: 2 tests passing

**Duration**: ~1 second

**Note**: Requires DATABASE_URL environment variable or connection string

#### Run pgvector Smoke Test (Optional)

```bash
# Run pgvector smoke test with real database (optional integration test)
python ai/rag/scripts/week7_pgvector_smoke_test.py \
    --query "What is the DataFlow pipeline?" \
    --document-external-id "doc_dataflow_technical_report" \
    --top-k 5 \
    --connection-string "$DATABASE_URL"
```

**Expected Output**: 5 chunks retrieved with similarity scores

**Duration**: ~50ms (depends on database latency)

**Note**: Requires real database connection

## GitHub Actions Workflow

### Example Workflow File

```yaml
name: RAG CI Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  rag-unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install dependencies
        run: |
          pip install pytest numpy scikit-learn
          pip install -e .
      
      - name: Run RAG unit tests
        run: python -m pytest ai/ai_tests/ -v --tb=short
      
      - name: Run CI smoke test
        run: python ai/rag/scripts/week7_rag_ci_smoke_test.py

  rag-ui-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install dependencies
        run: |
          pip install pytest numpy scikit-learn
          pip install -e .
      
      - name: Run RAG response contract tests
        run: python -m pytest ai/ai_tests/test_rag_response_contract.py -v
      
      - name: Run citation tests
        run: python -m pytest ai/ai_tests/test_citations.py -v
      
      - name: Validate UI fixture schema
        run: |
          python -c "
          import json
          with open('outputs/ui_fixtures/lap_rag_response_real.json') as f:
              data = json.load(f)
          required = ['question', 'answer', 'status', 'retrieved_context', 'citations', 'metadata']
          for field in required:
              assert field in data, f'Missing field: {field}'
          print('✓ UI fixture schema valid')
          "
```

## Local Development Commands

### For Duy

```bash
# Install dependencies
pip install pytest numpy scikit-learn
pip install -e .

# Run all tests
python -m pytest ai/ai_tests/ -v

# Run specific test file
python -m pytest ai/ai_tests/test_document_loader.py -v

# Run with coverage
python -m pytest ai/ai_tests/ --cov=ai.rag --cov-report=html
```

### For Phi/Hung

```bash
# Install dependencies
pip install pytest numpy scikit-learn
pip install -e .

# Run UI-related tests
python -m pytest ai/ai_tests/test_rag_response_contract.py ai/ai_tests/test_citations.py -v

# Validate fixture
python -c "
import json
with open('outputs/ui_fixtures/lap_rag_response_real.json') as f:
    data = json.load(f)
print(json.dumps(data, indent=2))
"
```

### For Phat

```bash
# Install dependencies
pip install pytest numpy scikit-learn psycopg2-binary
pip install -e .

# Set database URL
export DATABASE_URL="postgresql://user:password@localhost:5432/datavision"

# Run pgvector tests
python -m pytest ai/ai_tests/test_vector_store_pgvector_connection.py -v

# Run smoke test (optional)
python ai/rag/scripts/week7_pgvector_smoke_test.py \
    --query "What is the DataFlow pipeline?" \
    --document-external-id "doc_dataflow_technical_report" \
    --top-k 5
```

## Test Summary

### Test Categories

| Category | Test Files | Count | Duration | CI-Safe |
|----------|------------|-------|----------|---------|
| Unit Tests | ai/ai_tests/*.py | 59 | 6s | ✅ Yes |
| CI Smoke Test | week7_rag_ci_smoke_test.py | 10 | 2s | ✅ Yes |
| Document Loader | test_document_loader.py | 8 | 1s | ✅ Yes |
| RAG Contract | test_rag_response_contract.py | 6 | 1s | ✅ Yes |
| Citations | test_citations.py | 4 | 1s | ✅ Yes |
| pgvector Connection | test_vector_store_pgvector_connection.py | 2 | 1s | ✅ Yes |
| pgvector Smoke | week7_pgvector_smoke_test.py | 1 | 50ms | ❌ No |

### CI-Safe Tests

**Definition**: Tests that run without external dependencies (database, model downloads).

**Tests**:
- All pytest tests in ai/ai_tests/
- week7_rag_ci_smoke_test.py

**Total**: 69 tests

**Duration**: ~8 seconds

### Integration Tests

**Definition**: Tests that require external dependencies (database, real embeddings).

**Tests**:
- week7_pgvector_smoke_test.py (requires DATABASE_URL)
- load_document_pages_to_pgvector.py (requires DATABASE_URL)

**Total**: 2 scripts

**Duration**: ~1-2 seconds (depends on database)

## Troubleshooting

### Common Issues

#### Issue: pytest not found

```bash
# Solution: Install pytest
pip install pytest
```

#### Issue: numpy not found

```bash
# Solution: Install numpy
pip install numpy
```

#### Issue: scikit-learn not found

```bash
# Solution: Install scikit-learn
pip install scikit-learn
```

#### Issue: psycopg2 not found (for pgvector tests)

```bash
# Solution: Install psycopg2-binary
pip install psycopg2-binary
```

#### Issue: DATABASE_URL not set

```bash
# Solution: Set environment variable
export DATABASE_URL="postgresql://user:password@localhost:5432/datavision"
```

#### Issue: Tests failing with import errors

```bash
# Solution: Install package in development mode
pip install -e .
```

## CI Best Practices

### For GitHub Actions

1. **Use matrix strategy** for testing multiple Python versions
2. **Cache dependencies** to speed up builds
3. **Run tests in parallel** using pytest-xdist
4. **Upload test results** as artifacts
5. **Fail fast** on critical test failures

### Example Matrix Strategy

```yaml
strategy:
  matrix:
    python-version: ['3.9', '3.10', '3.11']
```

### Example Caching

```yaml
- name: Cache pip
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
```

## CI Status Monitoring

### Test Results Location

- **GitHub Actions**: Check Actions tab in repository
- **Local**: pytest output in terminal
- **Coverage**: htmlcov/index.html (if using --cov)

### Success Criteria

- **Unit Tests**: 59/59 passing
- **CI Smoke Test**: 10/10 passing
- **UI Contract**: 6/6 passing
- **Citations**: 4/4 passing
- **pgvector Connection**: 2/2 passing

## Notes for Duy

1. **CI-Safe**: All unit tests use fake implementations, no database needed
2. **Fast**: Full test suite runs in ~6 seconds
3. **Coverage**: Tests cover chunking, document loading, retrieval, citations
4. **Integration**: Optional pgvector tests require DATABASE_URL

## Notes for Phi/Hung

1. **UI Contract**: Tests validate response format matches UI expectations
2. **Citations**: Tests ensure citations include file_name, page_number, chunk_id
3. **Fixture**: lap_rag_response_real.json is the expected response format
4. **Schema**: Validation script checks required fields in fixture

## Notes for Phat

1. **Connection Tests**: Validate pgvector connection and schema
2. **Smoke Test**: Optional integration test with real database
3. **DATABASE_URL**: Required for pgvector tests
4. **Schema**: Tests expect schema_v4 tables (documents, document_chunks, rag_query_logs)

## Conclusion

These CI commands enable fast, reliable testing of the RAG module in GitHub Actions. The tests are CI-safe (no external dependencies) and run in under 10 seconds, making them suitable for PR checks and main branch protection.

The integration tests (pgvector smoke test) are optional and can be run separately when database infrastructure is available.
