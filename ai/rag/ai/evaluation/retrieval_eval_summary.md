# Retrieval Evaluation Summary

## Overview

This document summarizes the retrieval evaluation framework for the RAG system. The evaluation tests whether the retriever can correctly identify relevant document chunks for user queries.

## Test Cases File

**Location**: `ai/evaluation/retrieval_test_cases.csv`

**Columns**:
- `question`: User query to test
- `expected_chunk_id`: The chunk ID that should be retrieved
- `retrieved_chunk_id`: The chunk ID actually retrieved (to be filled)
- `similarity_score`: Cosine similarity score (to be filled)
- `hit_or_miss`: HIT if correct chunk retrieved, MISS otherwise (to be filled)
- `comment`: Notes about the test case

## Test Cases

### Current Test Suite (10 Questions)

1. **What is deep learning?** - Expected: `doc_001_chunk_002`
2. **How does reinforcement learning work?** - Expected: `doc_001_chunk_005`
3. **What is computer vision used for?** - Expected: `doc_001_chunk_004`
4. **Explain supervised learning** - Expected: `doc_001_chunk_006`
5. **What is unsupervised learning?** - Expected: `doc_001_chunk_007`
6. **What is machine learning?** - Expected: `doc_001_chunk_001`
7. **What is natural language processing?** - Expected: `doc_001_chunk_003`
8. **How do neural networks work?** - Expected: `doc_001_chunk_002`
9. **What are the applications of deep learning?** - Expected: `doc_001_chunk_002`
10. **What is the difference between supervised and unsupervised learning?** - Expected: `doc_001_chunk_006`

## Evaluation Metrics

### Primary Metrics

- **Hit Rate**: Percentage of queries where the expected chunk is in the top-k results
- **Mean Reciprocal Rank (MRR)**: Average of reciprocal ranks of correct chunks
- **Mean Similarity Score**: Average similarity score for retrieved chunks

### Secondary Metrics

- **Precision@k**: Percentage of relevant chunks in top-k results
- **Recall@k**: Percentage of relevant chunks retrieved in top-k results

## Running Evaluation

### Manual Evaluation

```python
import sys
sys.path.append('../../')

from ai.rag.embedder import load_embedding_model, embed_texts
from ai.rag.chunker import create_chunks
from ai.rag.retriever import retrieve_top_k
import pandas as pd

# Load test cases
test_cases = pd.read_csv('ai/evaluation/retrieval_test_cases.csv')

# Load model and prepare data
model = load_embedding_model()
# ... load chunks and embeddings ...

# Run evaluation
for idx, row in test_cases.iterrows():
    results = retrieve_top_k(row['question'], chunks, chunk_embeddings, model, top_k=5)
    # Update CSV with results
```

### Automated Evaluation Script

Create `ai/evaluation/run_evaluation.py` to automate the evaluation process.

## Expected Results

### Baseline Performance (Week 2)

With the current implementation using:
- Fixed-size chunking (512 chars, 50 overlap)
- all-MiniLM-L6-v2 embeddings (384 dimensions)
- Cosine similarity

**Expected metrics**:
- Hit Rate@5: ~70-80%
- Mean Similarity Score: ~0.6-0.8
- Precision@5: ~60-70%

### Factors Affecting Performance

**Positive factors**:
- Semantic embeddings capture meaning well
- Overlap helps preserve context
- Simple queries match chunk content directly

**Negative factors**:
- Fixed-size chunking may split concepts
- No query expansion or rewriting
- No reranking or filtering
- Limited to in-memory search

## Improvement Strategies

### Short-term (Week 3)

1. **Better Chunking**
   - Implement sentence-based chunking
   - Respect paragraph boundaries
   - Adjust chunk size based on content

2. **Query Processing**
   - Add query expansion
   - Implement query rewriting
   - Add spell correction

3. **Retrieval Enhancement**
   - Implement hybrid search (keyword + semantic)
   - Add relevance scoring
   - Implement reranking

### Long-term (Week 4+)

1. **Advanced Models**
   - Upgrade to larger embedding models
   - Use domain-specific models
   - Implement cross-encoders for reranking

2. **Context Understanding**
   - Add query classification
   - Implement intent detection
   - Add entity recognition

3. **Evaluation Framework**
   - Add more test cases
   - Implement automated evaluation
   - Add A/B testing

## Demo Preparation

### Friday Demo Requirements

For the Friday demo, show:
1. Load sample document text
2. Split it into chunks
3. Show chunk metadata
4. Generate embeddings
5. Ask a sample query
6. Retrieve top-3 relevant chunks
7. Show similarity scores
8. Show whether expected chunk was retrieved

### Demo Script

```python
# 1. Load sample document
sample_text = "..."

# 2. Chunk the document
chunks = create_chunks("doc_001", sample_text, metadata={"source": "demo.pdf"})

# 3. Show chunk metadata
print(f"Generated {len(chunks)} chunks")
print(f"First chunk: {chunks[0]}")

# 4. Generate embeddings
model = load_embedding_model()
chunk_embeddings = embed_texts([c['chunk_text'] for c in chunks], model)

# 5. Ask sample query
query = "What is deep learning?"

# 6. Retrieve top-3 chunks
results = retrieve_top_k(query, chunks, chunk_embeddings, model, top_k=3)

# 7. Show similarity scores
for result in results:
    print(f"Score: {result['similarity_score']:.4f}")

# 8. Check if expected chunk retrieved
expected_chunk_id = "doc_001_chunk_002"
retrieved_ids = [r['chunk_id'] for r in results]
hit = expected_chunk_id in retrieved_ids
print(f"Expected chunk retrieved: {hit}")
```

## Integration with pgvector

Once pgvector is integrated (Week 3), the evaluation will:

1. Store chunks and embeddings in PostgreSQL
2. Use pgvector's similarity search
3. Compare in-memory vs. database performance
4. Scale to larger document collections

## Next Steps

1. Run evaluation on current test cases
2. Fill in retrieved_chunk_id, similarity_score, hit_or_miss columns
3. Calculate baseline metrics
4. Identify failing test cases
5. Analyze failure patterns
6. Implement improvements
7. Re-run evaluation
8. Document performance gains

## References

- Information Retrieval Evaluation: https://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-ranked-retrieval-results-1.html
- RAG Evaluation Best Practices: Various research papers
