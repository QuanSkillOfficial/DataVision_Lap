# Week 4 Summary: Task Dependencies and Input/Output Flow

## Team Members and Roles

- **Lap** (RAG Team) - RAG pipeline implementation, embeddings, retrieval
- **Duy** - PDF extraction and document processing
- **Phi** - Backend integration and analytics dashboard
- **Hung** - Chatbot UI development

## Task Dependencies and Input/Output Flow

### 1. Duy → Lap (Document Processing Pipeline)

**Duy's Output → Lap's Input:**
- **Output**: `document_pages.jsonl` (extracted PDF pages with metadata)
- **Input**: Lap's `DocumentLoader.load_document_pages_jsonl()`
- **Dependency**: Lap's RAG pipeline depends on Duy's document extraction format
- **Flow**: Duy extracts PDFs → JSONL format → Lap loads and chunks → RAG pipeline

### 2. Lap → Phi (RAG Response Integration)

**Lap's Output → Phi's Input:**
- **Output**: RAG response (retrieved_context, citations, answer)
- **Input**: Phi's backend API and analytics database
- **Dependency**: Phi's dashboard depends on Lap's RAG response format
- **Flow**: Phi's backend sends query → Lap's RAG pipeline → RAG response → Phi's dashboard/database

### 3. Lap → Hung (Chatbot UI Integration)

**Lap's Output → Hung's Input:**
- **Output**: Retrieved context with citations (chunk_id, page_number, similarity_score)
- **Input**: Hung's chatbot UI for display
- **Dependency**: Hung's UI depends on Lap's citation format for source display
- **Flow**: Hung's UI sends question → Lap's RAG pipeline → Context + citations → Hung's UI display

### 4. Phi → Lap (Query Processing)

**Phi's Output → Lap's Input:**
- **Output**: User queries from backend
- **Input**: Lap's RAG pipeline query endpoint
- **Dependency**: Lap's RAG pipeline processes queries from Phi's backend
- **Flow**: Phi's backend → Query → Lap's RAG pipeline → Response

## Week 4 Specific Task Dependencies

### LLM Integration (Lap)
- **Depends on**: Week 3 retrieval system completion
- **Output**: Enhanced answer_generator with OpenAI API integration
- **Consumers**: Phi (backend), Hung (UI)
- **Input**: Retrieved chunks from Week 3 retriever

### Confidence Scoring (Lap)
- **Depends on**: LLM integration
- **Output**: Confidence scores in RAG responses
- **Consumers**: Phi (analytics dashboard), Hung (UI display)

### Scaled Evaluation (Lap)
- **Depends on**: Duy's larger document set (50+ documents)
- **Output**: Evaluation metrics on larger dataset
- **Consumers**: Team (quality assurance), Phi (dashboard benchmarks)

## Data Flow Summary

```
Duy (PDF Extraction)
    ↓ [document_pages.jsonl]
Lap (Document Loading & Chunking)
    ↓ [chunks with metadata]
Lap (Embedding Generation)
    ↓ [384-dim vectors]
Lap (Vector Storage)
    ↓ [indexed chunks]
    ↓
    ├──→ Phi (Backend) ←→ Lap (RAG Query Processing)
    │        ↓ [RAG response]
    │    Phi (Analytics Dashboard)
    │
    └──→ Hung (Chatbot UI) ←→ Lap (RAG Query Processing)
             ↓ [context + citations]
         Hung (UI Display)
```

## Critical Dependencies

1. **Duy → Lap**: Document format must match `document_pages.jsonl` contract
2. **Lap → Phi**: RAG response must follow `rag_response_contract.md`
3. **Lap → Hung**: Citation format must include chunk_id, page_number, similarity_score
4. **Phi → Lap**: Query format must match `rag_query_log_contract.md`

## Week 4 Integration Points

### Contract Documents
- `document_pages_to_chunks_contract.md` - Duy ↔ Lap
- `rag_response_contract.md` - Lap ↔ Phi/Hung
- `rag_query_log_contract.md` - Phi ↔ Lap

### API Endpoints
- Lap's RAG pipeline provides query endpoint
- Phi's backend consumes RAG responses
- Hung's UI displays retrieved context with citations

## Blockers and Risks

- **Blocker**: Duy's document extraction must be completed before large-scale evaluation
- **Risk**: LLM API costs need monitoring during Week 4 integration
- **Dependency**: Phi's backend must be ready to consume enhanced RAG responses with confidence scores

## Status

- **Week 3**: All integration contracts defined, basic RAG pipeline complete
- **Week 4**: LLM integration in progress, confidence scoring being added
- **Ready for**: Phi's backend integration, Hung's UI display enhancement
