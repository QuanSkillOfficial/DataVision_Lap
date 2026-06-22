# Embedding Model Test Notes

**Author:** Lap (AI Intern 1 - RAG and Embeddings Owner)  
**Week:** 1  
**Date:** May 15, 2026  
**Model**: sentence-transformers/all-MiniLM-L6-v2

## What We Tested

Check if the embedding model installs and works correctly. Tested on 3 sentences to confirm the environment is ready for Week 2.

## Test Setup

- **OS**: Windows
- **Python**: 3.13
- **Installed**:
  - sentence-transformers 5.5.0
  - scikit-learn
  - torch (via sentence-transformers)
  - transformers (via sentence-transformers)

## Installation

```bash
pip install sentence-transformers scikit-learn langchain psycopg2-binary
```

**Notes:**
- All packages installed fine
- Some dependency conflicts (gradio, instalooter) but not a problem for us
- Model downloaded automatically on first use (~90.9 MB)

## Test Sentences

Used 3 different sentences to test if the model captures meaning:

1. "The quick brown fox jumps over the lazy dog." - Basic sentence
2. "Machine learning is a subset of artificial intelligence." - AI/ML topic
3. "RAG combines retrieval with generation for better answers." - RAG topic

## Results

### Embeddings

- **Model**: all-MiniLM-L6-v2
- **Dimension**: 384
- **Output**: (3, 384) - 3 sentences, 384 dimensions each
- **Speed**: Fast (<1 second for 3 sentences)
-- **Status**: Works

### Similarity Matrix

|       | S1    | S2    | S3    |
|-------|-------|-------|-------|
| **S1** | 1.000 | 0.002 | 0.092 |
| **S2** | 0.002 | 1.000 | 0.129 |
| **S3** | 0.092 | 0.129 | 1.000 |

**What this means:**
- S2 and S3 are related (both AI/ML) - similarity 0.129
- S1 is unrelated to the technical ones - similarity near 0
- The model gets semantic relationships right

### Single Sentence

- **Input**: "This is a test sentence."
- **Output**: (1, 384)
-- **Status**: Works

## Performance

- **First run**: Downloads model (~90 MB), ~8 seconds
- **Cached runs**: Loads instantly
- **Inference**: <1 second for 3 sentences
- **Memory**: ~90 MB model size

## Model Info

### all-MiniLM-L6-v2
- **Architecture**: MiniLM, 6 layers
- **Parameters**: 22 million
- **Dimension**: 384
- **Max tokens**: 512
- **Pros**: Fast, good quality, small, open source
- **Cons**: Less accurate than bigger models

### Other Options

| Model | Dimension | Speed | Quality | Notes |
|-------|-----------|-------|---------|-------|
| all-MiniLM-L6-v2 | 384 | Fast | Good | What we're using |
| all-mpnet-base-v2 | 768 | Medium | Excellent | Upgrade option |
| text-embedding-3-small | 1536 | Fast | Excellent | OpenAI (costs money) |

## How to Use

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
embeddings = model.encode(sentences)
```

Similarity:
```python
from sklearn.metrics.pairwise import cosine_similarity
similarities = cosine_similarity(embeddings)
```

## Issues

### Deprecation Warning
- Method renamed: `get_sentence_embedding_dimension` → `get_embedding_dimension`
- Still works, just shows a warning
- Will fix in future updates

### Dependency Conflicts
- gradio and instalooter have conflicts
- Not relevant for our RAG work
- Ignored

## Next Steps

### For Week 2
1. Use this model for prototyping
2. Add caching to avoid recomputing
3. Use batch processing for efficiency
4. Monitor performance with more documents
5. Consider upgrading to mpnet if quality isn't good enough

### For Production
1. Test with real documents
2. Benchmark against other models
3. Consider GPU for large scale
4. Add embedding versioning
5. Set up monitoring

## Test Script

Test code is in `ai/rag/test_embedding.py`:
- Model initialization
- Batch embedding
- Similarity calculation
- Single sentence test
- Error handling

## Conclusion

**Test Passed**

Model installs and works correctly. Generates 384-dimensional embeddings and captures semantic meaning. Environment is ready for Week 2.

**Next**: Integrate with chunker, build vector store, create retriever, end-to-end pipeline.
