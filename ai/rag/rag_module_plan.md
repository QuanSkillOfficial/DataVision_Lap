# RAG Module Plan

**Author:** Lap (AI Intern 1 - RAG and Embeddings Owner)  
**Week:** 1  
**Date:** May 15, 2026

## What This Module Does

The RAG module lets users ask questions and get answers based on uploaded documents. Instead of just guessing, the system finds relevant chunks from the documents and uses those to generate accurate answers with sources.

## Module Structure

```
ai/
└── rag/
    ├── chunker.py          # Splits documents into chunks
    ├── embedder.py         # Turns text into vectors
    ├── vector_store.py     # Stores vectors for fast search
    ├── retriever.py        # Finds relevant chunks
    ├── rag_pipeline.py     # Ties everything together
    └── test_embedding.py   # Week 1 test
```

## Week 1: What Got Done

### Goals
- Understand how RAG works
- Set up the environment
- Install dependencies
- Test the embedding model
- Create the basic module structure

### Completed
- Created the directory structure
- Built basic module skeletons
- Installed dependencies (sentence-transformers, scikit-learn, langchain, psycopg2)
- Tested embedding model on 3 sentences - works!
- Documented the RAG architecture
- Wrote test notes
- Planned the development roadmap

### Deliverables
- `rag_architecture_understanding.md` - How RAG works
- `embedding_test_notes.md` - Test results
- `rag_module_plan.md` - This file
- Module skeleton files

---

## Dependencies (Week 1)

### What We Installed
```
sentence-transformers>=5.5.0
scikit-learn
langchain>=1.3.0
psycopg2-binary>=2.9.0
torch (via sentence-transformers)
transformers (via sentence-transformers)
```

### Install Command
```bash
pip install sentence-transformers scikit-learn langchain psycopg2-binary
```

---

## Technology Choices

### What We're Using
- **Embeddings**: sentence-transformers (all-MiniLM-L6-v2)
  - Fast, 384 dimensions, works well for most cases
  - Can upgrade to all-mpnet-base-v2 for better quality
- **Vector Database**: PostgreSQL with pgvector
  - Uses existing infrastructure
  - Reliable, SQL support
- **Framework**: LangChain
  - Well-documented, popular
- **Database Client**: psycopg2 for PostgreSQL

### Other Options We Considered
- **Vector Database**: Pinecone (cloud), Weaviate, ChromaDB
- **LLM**: OpenAI GPT-3.5-turbo / GPT-4 (for Week 2+)
- **Framework**: LlamaIndex as alternative to LangChain

---

## Conclusion

Week 1 is done. Environment is set up, dependencies installed, embedding model tested and working, module structure created. All documentation is complete.

The architecture docs give a clear path forward: chunking, embeddings, vector storage, retrieval, LLM integration, and citations. The modular design lets us build incrementally.

**Status**: Week 1 complete. Ready for Week 2.
