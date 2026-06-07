# RAG Architecture Understanding

**Author:** Lap (AI Intern 1 - RAG and Embeddings Owner)  
**Week:** 1  
**Date:** May 15, 2026

## What is RAG?

RAG (Retrieval-Augmented Generation) makes LLMs smarter by giving them relevant documents before they answer. Instead of guessing, the system finds the right information from your documents and uses that to generate accurate answers with sources.

This fixes common LLM problems: hallucinations, outdated knowledge, and lack of domain-specific info.

## How It Works

### 1. Document Text

**What it is:** The raw documents you upload - PDFs, text files, articles, etc.

**What we do:**
- Clean up the text (remove headers, footers, formatting noise)
- Extract metadata (author, date, source, tags)
- Support multiple formats (PDF, TXT, MD, DOCX)
- Track document versions

---

### 2. Chunking

**What it is:** Breaking big documents into smaller pieces.

**Why:** Large documents can't be embedded all at once. We split them into manageable chunks.

**How we do it:**
- **Fixed-size**: Split every N characters (simple but may break sentences)
- **Sentence-based**: Split at sentence boundaries (keeps sentences intact)
- **Semantic**: Split based on meaning using embeddings (best quality, coming in Week 2)

**Settings:**
- Chunk size: 512 characters (default)
- Overlap: 50 characters between chunks (preserves context)

---

### 3. Embedding

**What it is:** Turning text into numbers (vectors) that capture meaning.

**How it works:**
- Similar texts get similar vectors
- We use sentence-transformers (all-MiniLM-L6-v2)
- 384 dimensions per vector
- Enables semantic search (finds related content, not just keywords)

**Model choices:**
- all-MiniLM-L6-v2: Fast, good quality (what we're using)
- all-mpnet-base-v2: Slower but better quality (upgrade option)
- OpenAI embeddings: Higher quality but costs money

---

### 4. pgvector Storage

**What it is:** Storing the embeddings in a database for fast search.

**Why pgvector:**
- PostgreSQL extension for vector data
- Works with existing infrastructure
- Reliable, SQL support, ACID transactions
- Can handle millions of vectors with proper indexing

**Database structure:**
```sql
CREATE TABLE document_chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id),
    chunk_text TEXT NOT NULL,
    embedding vector(384),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Alternatives:** Pinecone (cloud), Weaviate, ChromaDB

---

### 5. Retrieval

**What it is:** Finding the most relevant chunks for a user's question.

**How it works:**
1. Embed the user's question (same model as documents)
2. Search the vector database for similar embeddings
3. Rank by similarity score
4. Return top-k results (default: 5)

**Advanced options (future):**
- Hybrid search (vector + keyword)
- Reranking with cross-encoders
- Query expansion
- Recursive retrieval

---

### 6. LLM Answer

**What it is:** Generating a response using the retrieved chunks as context.

**How it works:**
- Format the retrieved chunks as context
- Send to LLM with a prompt that says "use only this context"
- LLM synthesizes information from multiple chunks
- Returns a natural language answer

**Prompt example:**
```
Answer this question using only the provided context.
If the context doesn't have the answer, say "I don't know."

Context: {retrieved_chunks}
Question: {user_query}
Answer:
```

**LLM options:**
- GPT-3.5-turbo: Cost-effective (starting point)
- GPT-4: Better quality for complex queries
- Local models: For privacy-sensitive data

---

### 7. Source Citation

**What it is:** Showing which documents contributed to the answer.

**Why it matters:**
- Transparency - users can verify information
- Fact-checking
- Builds trust
- Compliance in some domains

**What we include:**
- Document ID/title
- Chunk excerpt
- Similarity score (confidence)
- Link to original document
- Metadata (author, date, source)

---

## The Full Flow

```
User asks a question
    ↓
Embed the question
    ↓
Search pgvector for similar chunks
    ↓
Get top-k most relevant chunks
    ↓
Format chunks as context + citations
    ↓
Send to LLM with prompt
    ↓
Generate answer
    ↓
Return answer + sources
```

## Key Design Decisions

1. **Chunking**: Sentence-based with overlap (balances quality and speed)
2. **Embedding Model**: all-MiniLM-L6-v2 (fast, can upgrade to mpnet)
3. **Vector Store**: pgvector (uses existing PostgreSQL)
4. **Retrieval**: Basic vector search with metadata filtering
5. **LLM**: GPT-3.5-turbo (cost-effective, can upgrade to GPT-4)
6. **Citations**: Automatic with document links and similarity scores

## Why RAG is Good

- **Less hallucinations**: LLM uses actual documents, not just guessing
- **Always current**: Add new documents to update knowledge
- **Domain-specific**: Tailored to your organization's data
- **Transparent**: Shows sources so you can verify
- **Cost-effective**: No need to fine-tune LLMs
- **Scalable**: Can handle millions of documents

## Limitations and How We Handle Them

| Problem | Solution |
|---------|----------|
| Bad retrieval = bad answers | Hybrid search, reranking, better chunking |
| Context window limits | Summarize chunks, use larger models |
| Outdated documents | Versioning, expiration dates |
| Complex reasoning | Recursive retrieval, chain-of-thought |
| Computational cost | Caching, batch processing, efficient indexing |

## Next Steps (Week 2)

- Build chunking notebook with multiple strategies
- Create semantic search prototype
- Develop early RAG pipeline components
- Test with sample documents
- Evaluate retrieval quality
