"""
Vector Store - Stores embeddings for fast similarity search

Uses pgvector (PostgreSQL) for production, in-memory for testing.
Embeddings are stored alongside text and metadata for retrieval.
Preserves original chunk IDs and document structure.
"""

from typing import List, Dict, Optional, Tuple
import numpy as np


class VectorStore:
    """Stores and retrieves embeddings - pgvector for prod, in-memory for testing."""
    
    def __init__(self, use_pgvector: bool = False, connection_string: Optional[str] = None):
        self.use_pgvector = use_pgvector
        self.connection_string = connection_string
        self.connection = None
        self.in_memory_store = {}  # chunk_id -> chunk_data
        
        if use_pgvector:
            self._connect_pgvector()
    
    def _connect_pgvector(self):
        """Connect to PostgreSQL with pgvector (Week 3)."""
        try:
            import psycopg2
            self.connection = psycopg2.connect(self.connection_string)
            print("Connected to PostgreSQL with pgvector")
            self._create_table()
        except ImportError:
            print("Need psycopg2 - run: pip install psycopg2-binary")
            self.use_pgvector = False
        except Exception as e:
            print(f"PostgreSQL connection failed: {e}")
            self.use_pgvector = False
    
    def _create_table(self):
        """Create document_chunks table with pgvector (Week 3)."""
        if not self.connection:
            return
        
        try:
            cursor = self.connection.cursor()
            
            # Enable pgvector extension
            cursor.execute("CREATE EXTENSION IF NOT EXISTS vector")
            
            # Create table with proper schema
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS document_chunks (
                    id SERIAL PRIMARY KEY,
                    chunk_id VARCHAR(255) UNIQUE NOT NULL,
                    document_id VARCHAR(255) NOT NULL,
                    chunk_text TEXT NOT NULL,
                    embedding vector(384),
                    page_number INTEGER,
                    metadata JSONB,
                    start_char INTEGER,
                    end_char INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                
                CREATE INDEX IF NOT EXISTS idx_chunk_id ON document_chunks (chunk_id);
                CREATE INDEX IF NOT EXISTS idx_document_id ON document_chunks (document_id);
                CREATE INDEX IF NOT EXISTS idx_page_number ON document_chunks (page_number);
                CREATE INDEX IF NOT EXISTS idx_embedding ON document_chunks USING ivfflat (embedding vector_cosine_ops);
            """)
            
            self.connection.commit()
            print(" Created document_chunks table with pgvector")
        except Exception as e:
            print(f"Error creating table: {e}")
            self.connection.rollback()
    
    def add_chunks(
        self,
        chunks: List[Dict],
        embeddings: np.ndarray
    ) -> List[str]:
        """
        Store chunks with their embeddings (preserves chunk IDs).
        
        Args:
            chunks: List of chunk dicts with chunk_id, document_id, chunk_text, metadata, etc.
            embeddings: NumPy array of embeddings (one per chunk)
        
        Returns:
            List of chunk IDs that were stored
        """
        if self.use_pgvector and self.connection:
            return self._add_chunks_pgvector(chunks, embeddings)
        else:
            return self._add_chunks_in_memory(chunks, embeddings)
    
    def _add_chunks_pgvector(self, chunks: List[Dict], embeddings: np.ndarray) -> List[str]:
        """Add chunks to pgvector (Week 3)."""
        if not self.connection:
            raise RuntimeError("Not connected to pgvector")
        
        import json
        try:
            cursor = self.connection.cursor()
            chunk_ids = []
            
            for chunk, embedding in zip(chunks, embeddings):
                chunk_id = chunk["chunk_id"]
                document_id = chunk["document_id"]
                chunk_text = chunk["chunk_text"]
                metadata = json.dumps(chunk.get("metadata", {}))
                page_number = chunk.get("metadata", {}).get("page_number")
                start_char = chunk.get("start_char")
                end_char = chunk.get("end_char")
                
                # Convert embedding to pgvector format
                embedding_str = str(embedding.tolist())
                
                cursor.execute("""
                    INSERT INTO document_chunks 
                    (chunk_id, document_id, chunk_text, embedding, page_number, metadata, start_char, end_char)
                    VALUES (%s, %s, %s, %s::vector, %s, %s::jsonb, %s, %s)
                    ON CONFLICT (chunk_id) DO UPDATE SET
                        embedding = EXCLUDED.embedding,
                        metadata = EXCLUDED.metadata
                """, (chunk_id, document_id, chunk_text, embedding_str, page_number, metadata, start_char, end_char))
                
                chunk_ids.append(chunk_id)
            
            self.connection.commit()
            print(f" Added {len(chunk_ids)} chunks to pgvector")
            return chunk_ids
            
        except Exception as e:
            print(f"Error adding chunks to pgvector: {e}")
            self.connection.rollback()
            raise
    
    def _add_chunks_in_memory(self, chunks: List[Dict], embeddings: np.ndarray) -> List[str]:
        """Add chunks to in-memory store while preserving chunk IDs."""
        chunk_ids = []
        
        for chunk, embedding in zip(chunks, embeddings):
            chunk_id = chunk["chunk_id"]
            
            self.in_memory_store[chunk_id] = {
                "chunk_id": chunk["chunk_id"],
                "document_id": chunk["document_id"],
                "chunk_text": chunk["chunk_text"],
                "embedding": embedding,
                "metadata": chunk.get("metadata", {}),
                "start_char": chunk.get("start_char"),
                "end_char": chunk.get("end_char"),
                "chunk_index": chunk.get("chunk_index", 0)
            }
            
            chunk_ids.append(chunk_id)
        
        return chunk_ids
    
    def add_embeddings(
        self,
        embeddings: np.ndarray,
        texts: List[str],
        metadata: Optional[List[Dict]] = None
    ) -> List[str]:
        """
        DEPRECATED: Use add_chunks() instead. 
        Store embeddings with their text and metadata (legacy API).
        """
        import warnings
        warnings.warn(
            "add_embeddings() is deprecated. Use add_chunks() with full chunk dicts instead.",
            DeprecationWarning
        )
        
        chunks = []
        for i, text in enumerate(texts):
            chunk = {
                "chunk_id": f"legacy_doc_{i}",
                "document_id": f"legacy_doc",
                "chunk_text": text,
                "metadata": metadata[i] if metadata else {},
                "start_char": 0,
                "end_char": len(text),
                "chunk_index": i
            }
            chunks.append(chunk)
        
        return self.add_chunks(chunks, embeddings)
    
    def search(
        self,
        query_embedding: np.ndarray,
        top_k: int = 5,
        filter_metadata: Optional[Dict] = None
    ) -> List[Dict]:
        """Find similar embeddings using cosine similarity."""
        if self.use_pgvector and self.connection:
            return self._search_pgvector(query_embedding, top_k, filter_metadata)
        else:
            return self._search_in_memory(query_embedding, top_k, filter_metadata)
    
    def _search_pgvector(
        self,
        query_embedding: np.ndarray,
        top_k: int,
        filter_metadata: Optional[Dict]
    ) -> List[Dict]:
        """Search pgvector for similar embeddings (Week 3)."""
        if not self.connection:
            raise RuntimeError("Not connected to pgvector")
        
        try:
            cursor = self.connection.cursor()
            embedding_str = str(query_embedding.tolist())
            
            # Build WHERE clause for filtering
            where_clause = "WHERE 1=1"
            params = [embedding_str]
            
            if filter_metadata:
                if "document_id" in filter_metadata:
                    where_clause += " AND document_id = %s"
                    params.append(filter_metadata["document_id"])
                if "page_number" in filter_metadata:
                    where_clause += " AND page_number = %s"
                    params.append(filter_metadata["page_number"])
            
            query = f"""
                SELECT 
                    chunk_id,
                    document_id,
                    chunk_text,
                    page_number,
                    metadata,
                    1 - (embedding <=> %s::vector) AS similarity_score
                FROM document_chunks
                {where_clause}
                ORDER BY embedding <=> %s::vector
                LIMIT %s
            """
            
            params.extend([embedding_str, top_k])
            cursor.execute(query, params)
            
            results = []
            for row in cursor.fetchall():
                import json
                results.append({
                    "chunk_id": row[0],
                    "document_id": row[1],
                    "text": row[2],
                    "chunk_text": row[2],
                    "page_number": row[3],
                    "metadata": json.loads(row[4]) if isinstance(row[4], str) else row[4],
                    "score": float(row[5])
                })
            
            return results
            
        except Exception as e:
            print(f"Error searching pgvector: {e}")
            raise
    
    def _search_in_memory(
        self,
        query_embedding: np.ndarray,
        top_k: int,
        filter_metadata: Optional[Dict]
    ) -> List[Dict]:
        """Search in-memory store with cosine similarity."""
        from sklearn.metrics.pairwise import cosine_similarity
        
        results = []
        query_embedding = query_embedding.reshape(1, -1)
        
        for chunk_id, chunk_data in self.in_memory_store.items():
            # Apply metadata filtering
            if filter_metadata:
                match = True
                if "document_id" in filter_metadata:
                    if chunk_data.get("document_id") != filter_metadata["document_id"]:
                        match = False
                if "page_number" in filter_metadata:
                    page = chunk_data.get("metadata", {}).get("page_number")
                    if page != filter_metadata["page_number"]:
                        match = False
                
                if not match:
                    continue
            
            embedding = chunk_data["embedding"].reshape(1, -1)
            similarity = cosine_similarity(query_embedding, embedding)[0][0]
            
            results.append({
                "chunk_id": chunk_data["chunk_id"],
                "document_id": chunk_data["document_id"],
                "id": chunk_id,
                "text": chunk_data["chunk_text"],
                "chunk_text": chunk_data["chunk_text"],
                "score": float(similarity),
                "metadata": chunk_data.get("metadata", {})
            })
        
        results.sort(key=lambda x: x["score"], reverse=True)
        return results[:top_k]
    
    def delete(self, chunk_ids: List[str]) -> bool:
        """Remove chunks by their IDs."""
        for chunk_id in chunk_ids:
            if chunk_id in self.in_memory_store:
                del self.in_memory_store[chunk_id]
        return True
    
    def clear(self) -> bool:
        """Wipe all embeddings from the store."""
        self.in_memory_store.clear()
        return True
    
    def get_chunk(self, chunk_id: str) -> Optional[Dict]:
        """Retrieve a chunk by its ID."""
        return self.in_memory_store.get(chunk_id)
    
    def get_all_chunks_for_document(self, document_id: str) -> List[Dict]:
        """Get all chunks for a specific document."""
        return [
            chunk for chunk in self.in_memory_store.values()
            if chunk["document_id"] == document_id
        ]


if __name__ == "__main__":
    # Test the vector store
    print("=== Testing VectorStore ===\n")
    
    # Create in-memory store
    vector_store = VectorStore(use_pgvector=False)
    
    # Create sample chunks
    chunks = [
        {
            "chunk_id": "doc_001_chunk_000",
            "document_id": "doc_001",
            "chunk_text": "Machine learning is a subset of artificial intelligence.",
            "metadata": {"source": "ai_guide.pdf", "page_number": 1},
            "start_char": 0,
            "end_char": 57
        },
        {
            "chunk_id": "doc_001_chunk_001",
            "document_id": "doc_001",
            "chunk_text": "Deep learning uses neural networks with multiple layers.",
            "metadata": {"source": "ai_guide.pdf", "page_number": 2},
            "start_char": 58,
            "end_char": 113
        },
        {
            "chunk_id": "doc_001_chunk_002",
            "document_id": "doc_001",
            "chunk_text": "Natural language processing handles human language understanding.",
            "metadata": {"source": "ai_guide.pdf", "page_number": 2},
            "start_char": 114,
            "end_char": 177
        }
    ]
    
    # Create dummy embeddings
    embeddings = np.random.rand(3, 384)
    
    # Add chunks (preserves chunk IDs!)
    print("Adding chunks...")
    added_ids = vector_store.add_chunks(chunks, embeddings)
    print(f" Added {len(added_ids)} chunks")
    print(f"  Chunk IDs: {added_ids}\n")
    
    # Search
    print("Searching...")
    query_embedding = np.random.rand(384)
    results = vector_store.search(query_embedding, top_k=2)
    print(f" Found {len(results)} results:")
    for result in results:
        print(f"  - {result['chunk_id']}: score={result['score']:.4f}")
        print(f"    Document: {result['document_id']}")
        print(f"    Page: {result.get('metadata', {}).get('page_number')}\n")
    
    # Test metadata filtering
    print("Searching with document_id filter...")
    filtered_results = vector_store.search(
        query_embedding,
        top_k=5,
        filter_metadata={"document_id": "doc_001"}
    )
    print(f" Found {len(filtered_results)} results for doc_001\n")

