-- 1. Metadata Validation (Check if Tables & Views exist)
-- ==========================================
-- This should list exactly 10 tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- This should list exactly 7 views (v_dashboard_overview, etc.)
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'VIEW';

-- ==========================================
-- 2. Foreign Key Integrity Checks (Orphan checks)
-- ==========================================
-- Check 2.1: Do all document_pages link to a valid document? (Expected: 0)
SELECT COUNT(*) AS orphaned_pages 
FROM document_pages dp 
LEFT JOIN documents d ON dp.document_id = d.id 
WHERE d.id IS NULL;

-- Check 2.2: Do all document_chunks link to a valid document? (Expected: 0)
SELECT COUNT(*) AS orphaned_chunks 
FROM document_chunks dc 
LEFT JOIN documents d ON dc.document_id = d.id 
WHERE d.id IS NULL;

-- Check 2.3: Do all structured_records link to a valid source? (Expected: 0)
SELECT COUNT(*) AS orphaned_records 
FROM structured_records sr 
LEFT JOIN sources s ON sr.source_id = s.id 
WHERE s.id IS NULL;

-- ==========================================
-- 3. Vector & RAG Data Quality Checks
-- ==========================================
-- Check 3.1: Are there any null embeddings? (Expected: 0)
SELECT COUNT(*) AS missing_embeddings 
FROM document_chunks 
WHERE embedding IS NULL;

-- Check 3.2: Are all embeddings exactly 384 dimensions? (Expected: 0)
-- Note: vector_dims() is a built-in pgvector function
SELECT COUNT(*) AS invalid_vector_dimensions 
FROM document_chunks 
WHERE vector_dims(embedding) != 384;

-- Check 3.3: Do RAG logs properly contain retrieved_chunk_ids? (Expected: 0)
SELECT COUNT(*) AS missing_retrieved_chunks 
FROM rag_query_logs 
WHERE retrieved_chunk_ids IS NULL OR jsonb_array_length(retrieved_chunk_ids) = 0;

-- ==========================================
-- 4. Pipeline & Log Data Quality Checks
-- ==========================================
-- Check 4.1: Do all ingestion logs have a run_id assigned? (Expected: 0)
SELECT COUNT(*) AS missing_run_id_logs 
FROM ingestion_logs 
WHERE run_id IS NULL OR TRIM(run_id) = '';

-- Check 4.2: Are there any invalid status values bypassing constraints? (Expected: 0)
SELECT COUNT(*) AS invalid_status_logs 
FROM ingestion_logs 
WHERE status NOT IN ('success', 'failed', 'partial_success', 'running');

-- Check 4.3: Do prediction logs correctly contain a confidence score? (Expected: 0)
SELECT COUNT(*) AS missing_confidence_scores 
FROM prediction_logs 
WHERE confidence_score IS NULL;

-- ==========================================
-- 5. Dashboard Data Ready Check
-- ==========================================
-- Ensure the main dashboard view is calculating successfully
SELECT * FROM v_dashboard_overview;