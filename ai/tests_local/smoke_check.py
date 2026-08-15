import sys
sys.path.append(r'c:/Users/WINDOWS/Downloads/DataVision_Lap-main/DataVision_Lap-main')
from ai.rag.embedder import Embedder
from ai.rag.vector_store import VectorStore
import numpy as np

def main():
    try:
        e = Embedder(mode='deterministic')
        v = VectorStore(use_pgvector=False)
        texts = ['Hello world', 'Another text']
        embs = e.embed(texts)
        print('emb shape:', embs.shape)
        chunks = [{'chunk_id':'c1','document_id':'d1','chunk_text':'Hello','metadata':{'source':'s','page_number':1}}]
        v.add_chunks(chunks, embs[:1])
        print('in_memory_store keys:', list(v.in_memory_store.keys()))
        v.delete(['c1'])
        print('after delete keys:', list(v.in_memory_store.keys()))
    except Exception as ex:
        print('ERROR', ex)

if __name__ == '__main__':
    main()
