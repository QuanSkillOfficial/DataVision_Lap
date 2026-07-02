"""
Test the embedding model on 3 sample sentences

Verifies installation and basic functionality.
"""

import sys
sys.path.append('.')

import numpy as np

try:
    from .embedder import Embedder
except ImportError:  # pragma: no cover - direct script execution fallback
    from embedder import Embedder


def test_embedding_model():
    """Test embedding model on 3 sample sentences."""
    
    print("=" * 60)
    print("EMBEDDING MODEL TEST - Week 1")
    print("=" * 60)
    
    print("\n1. Loading model...")
    embedder = Embedder(model_name="sentence-transformers/all-MiniLM-L6-v2")
    
    test_sentences = [
        "The quick brown fox jumps over the lazy dog.",
        "Machine learning is a subset of artificial intelligence.",
        "RAG combines retrieval with generation for better answers."
    ]
    
    print("\n2. Test sentences:")
    for i, sentence in enumerate(test_sentences, 1):
        print(f"   {i}. {sentence}")
    
    print("\n3. Generating embeddings...")
    embeddings = embedder.embed(test_sentences)
    
    print(f"   Shape: {embeddings.shape}")
    print(f"   Dimension: {embedder.get_embedding_dimension()}")
    
    print("\n4. Calculating similarities...")
    from sklearn.metrics.pairwise import cosine_similarity
    
    similarity_matrix = cosine_similarity(embeddings)
    
    print("\n   Similarity Matrix:")
    print("   " + " ".join([f"S{i+1:<6}" for i in range(len(test_sentences))]))
    for i in range(len(test_sentences)):
        row = " ".join([f"{similarity_matrix[i][j]:.3f}  " for j in range(len(test_sentences))])
        print(f"   S{i+1} {row}")
    
    print("\n5. Testing single sentence...")
    single_embedding = embedder.embed_query("This is a test sentence.")
    print(f"   Shape: {single_embedding.shape}")
    
    print("\n" + "=" * 60)
    print("TEST COMPLETED")
    print("=" * 60)
    
    return {
        "embeddings": embeddings,
        "similarity_matrix": similarity_matrix,
        "dimension": embedder.get_embedding_dimension()
    }


if __name__ == "__main__":
    try:
        results = test_embedding_model()
        print("\n All tests passed!")
    except Exception as e:
        print(f"\n Test failed: {e}")
        import traceback
        traceback.print_exc()
