CREATE EXTENSION IF NOT EXISTS vector;
-- 1. sources
CREATE TABLE sources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    source_type VARCHAR(50) NOT NULL,
    source_format VARCHAR(50),
    source_path TEXT,
    url TEXT,
    owner_name VARCHAR(100),
    authentication_required BOOLEAN DEFAULT FALSE,
    schema_version VARCHAR(50),
    sample_available BOOLEAN DEFAULT FALSE,
    expected_volume VARCHAR(100),
    sensitive_data_flag BOOLEAN DEFAULT FALSE,
    downstream_consumer TEXT,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- 2. pipeline_runs
CREATE TABLE pipeline_runs (
    id SERIAL PRIMARY KEY,
    run_name VARCHAR(255),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(50) DEFAULT 'running',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. documents
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    source_id INT REFERENCES sources(id) ON DELETE CASCADE,
    file_name VARCHAR(255),
    file_type VARCHAR(50),
    file_size_bytes BIGINT,
    file_hash_sha256 VARCHAR(255),
    raw_path TEXT,
    staging_text_path TEXT,
    page_count INT,
    character_count INT,
    document_metadata JSONB,
    processing_status VARCHAR(50) DEFAULT 'uploaded',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT chk_document_processing_status 
        CHECK (processing_status IN ('uploaded', 'extracted', 'chunked', 'embedded', 'processed', 'failed'))
);
-- 4. document_chunks
CREATE TABLE document_chunks (
    id SERIAL PRIMARY KEY,
    chunk_id VARCHAR(255) UNIQUE NOT NULL,
    document_id INT REFERENCES documents(id) ON DELETE CASCADE,
    page_number INT,
    chunk_text TEXT NOT NULL,
    chunk_index INT,
    embedding vector(384),
    embedding_model VARCHAR(100) DEFAULT 'all-MiniLM-L6-v2',
    embedding_dimension INT DEFAULT 384,
    chunk_metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 5. structured_records
CREATE TABLE structured_records (
    id SERIAL PRIMARY KEY,
    source_id INT REFERENCES sources(id) ON DELETE CASCADE,
    record_data JSONB NOT NULL,
    status VARCHAR(50) DEFAULT 'clean',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. ingestion_logs
CREATE TABLE ingestion_logs (
    id SERIAL PRIMARY KEY,
    run_id VARCHAR(100),
    source_id INT REFERENCES sources(id) ON DELETE CASCADE,
    pipeline_run_id INT REFERENCES pipeline_runs(id) ON DELETE SET NULL,
    source_type VARCHAR(50),
    input_path_or_url TEXT,
    status VARCHAR(50),
    records_read INT,
    records_valid INT,
    records_invalid INT,
    error_message TEXT,
    raw_output_path TEXT,
    staging_output_path TEXT,
    clean_output_path TEXT,
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ingestion_status 
    CHECK (status IN ('success', 'failed', 'partial_success', 'running'))
);

-- 7. analytics_events
CREATE TABLE analytics_events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    user_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. rag_query_logs
CREATE TABLE rag_query_logs (
    id SERIAL PRIMARY KEY,
    document_id INT REFERENCES documents(id) ON DELETE SET NULL,
    user_query TEXT NOT NULL,
    retrieved_chunk_ids JSONB,
    retrieval_scores JSONB,
    generated_response TEXT,
    answer_confidence FLOAT,
    latency_ms INT,
    model_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. prediction_logs
CREATE TABLE prediction_logs (
    id SERIAL PRIMARY KEY,
    source_id INT REFERENCES sources(id) ON DELETE SET NULL,
    document_id INT REFERENCES documents(id) ON DELETE SET NULL,
    structured_record_id INT REFERENCES structured_records(id) ON DELETE SET NULL,
    model_name VARCHAR(100),
    model_version VARCHAR(50),
    input_payload JSONB,
    prediction_result JSONB,
    predicted_label VARCHAR(100),
    confidence_score FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. document_pages
CREATE TABLE document_pages (
    id SERIAL PRIMARY KEY,
    document_id INT REFERENCES documents(id) ON DELETE CASCADE,
    page_number INT NOT NULL,
    page_text TEXT,
    character_count INT,
    is_empty BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create basic indexes for performance
CREATE INDEX idx_documents_source_id ON documents(source_id);
CREATE INDEX idx_chunks_document_id ON document_chunks(document_id);
CREATE INDEX idx_logs_pipeline_id ON ingestion_logs(pipeline_run_id);
CREATE INDEX idx_pages_document_id ON document_pages(document_id);
CREATE INDEX idx_document_chunks_embedding_hnsw ON document_chunks USING hnsw (embedding vector_cosine_ops);
-- DROP TABLE documents CASCADE;

-- 1. PIPELINE RUNS
-- ==========================================
INSERT INTO pipeline_runs (run_name, status, start_time, end_time) VALUES
('week3_real_data_ingestion_01', 'completed', CURRENT_TIMESTAMP - INTERVAL '1 hour', CURRENT_TIMESTAMP);

-- ==========================================
-- 2. SOURCES
-- ==========================================
INSERT INTO sources (name, source_type, source_format, source_path, url, expected_volume, status) VALUES
('Superstore CSV', 'local_file', 'csv', 'data/raw/superstore.csv', NULL, '9,994 rows', 'active'),
('Product Sales Region Excel', 'local_file', 'xlsx', 'data/raw/product_sales_region_clean.csv', NULL, '10 rows', 'active'),
('DummyJSON Products API', 'rest_api', 'json', NULL, 'https://dummyjson.com/products', '10 items', 'active'),
('DataFlow Technical Report PDF', 'local_file', 'pdf', 'data/raw/dataflow_report.pdf', NULL, '1 document', 'active');

-- ==========================================
-- 3. DOCUMENTS 
-- ==========================================
INSERT INTO documents (source_id, file_name, file_type, file_size_bytes, page_count, processing_status) VALUES
(1, 'superstore.csv', 'csv', 500000, 0, 'processed'),
(2, 'product_sales_region_clean.csv', 'csv', 15000, 0, 'processed'),
(4, 'dataflow_report.pdf', 'pdf', 3145728, 3, 'processed');

-- ==========================================
-- 4. DOCUMENT PAGES (Real DataFlow PDF Extractions)
-- ==========================================
INSERT INTO document_pages (document_id, page_number, page_text, character_count, is_empty) VALUES
(3, 2, 'December 19, 2025 DataFlow: An LLM-Driven Framework for Unified Data Preparation and Workflow Automation in the Era of Data-Centric AI Hao Liang*, Xiaochen Ma*, Zhou Liu*... The rapidly growing demand for high-quality data in Large Language Models (LLMs) has intensified the need for scalable, reliable, and semantically rich data preparation pipelines.', 2953, FALSE),
(3, 3, 'Contents 1 Introduction . . . . . . . 4 2 Background and Related Works . . . . . . . 6 2.1 Data in LLM Development . . . . . . . 6 2.2 Data Preparation for LLMs . . . . . . . 6 3 DataFlow System Overview . . . . . . . 7', 343, FALSE),
(3, 4, 'DataFlow Technical Report 4 1 Introduction Large language models (LLMs) have rapidly evolved from research prototypes to foundational infrastructure across natural language processing and beyond. Since OpenAI introduced the GPT family through large-scale human annotation and ignited the era of large language models (LLMs), scaling-law studies have consistently demonstrated that data quality and quantity are central to model performance.', 4914, FALSE);

-- ==========================================
-- 5. DOCUMENT CHUNKS (RAG Preparation - 384 dims mock)
-- ==========================================
INSERT INTO document_chunks (chunk_id, document_id, page_number, chunk_text, chunk_index, embedding) VALUES
('doc_003_page_2_chunk_000', 3, 2, 'DataFlow: An LLM-Driven Framework for Unified Data Preparation and Workflow Automation in the Era of Data-Centric AI', 0, ('[' || array_to_string(array_fill(0.015, ARRAY[384]), ',') || ']')::vector),
('doc_003_page_4_chunk_001', 3, 4, '1 Introduction Large language models (LLMs) have rapidly evolved from research prototypes to foundational infrastructure across natural language processing.', 1, ('[' || array_to_string(array_fill(0.021, ARRAY[384]), ',') || ']')::vector);

-- ==========================================
-- 6. STRUCTURED RECORDS (Real Parsed Output)
-- ==========================================

-- A. Superstore CSV (From uploaded image)
INSERT INTO structured_records (source_id, record_data, status) VALUES
(1, '{"Row ID": 1, "Order ID": "CA-2023-152156", "Order Date": "2023-11-08", "Ship Mode": "Second Class", "Customer Name": "Claire Gute", "Segment": "Consumer", "Country": "United States", "City": "Henderson", "State": "Kentucky", "Region": "South", "Category": "Furniture", "Sub-Category": "Bookcases", "Sales": 261.96, "Quantity": 2, "Profit": 41.9136}', 'clean'),
(1, '{"Row ID": 2, "Order ID": "CA-2023-152156", "Order Date": "2023-11-08", "Ship Mode": "Second Class", "Customer Name": "Claire Gute", "Segment": "Consumer", "Country": "United States", "City": "Henderson", "State": "Kentucky", "Region": "South", "Category": "Furniture", "Sub-Category": "Chairs", "Sales": 731.94, "Quantity": 3, "Profit": 219.582}', 'clean'),
(1, '{"Row ID": 3, "Order ID": "CA-2023-138688", "Order Date": "2023-06-12", "Ship Mode": "Second Class", "Customer Name": "Darrin Van Huff", "Segment": "Corporate", "Country": "United States", "City": "Los Angeles", "State": "California", "Region": "West", "Category": "Office Supplies", "Sub-Category": "Labels", "Sales": 14.62, "Quantity": 2, "Profit": 6.8714}', 'clean');

-- B. Product Sales Region Excel 
INSERT INTO structured_records (source_id, record_data, status) VALUES
(2, '{"date": "2023-02-23", "region": "East", "product": "Laptop", "quantity": 14, "unitprice": 163.6, "storelocation": "Store B", "customertype": "Wholesale", "salesperson": "Eva", "totalprice": 2290.4, "paymentmethod": "Online", "orderid": "REG100000", "manager": "Eric"}', 'clean'),
(2, '{"date": "2024-12-19", "region": "South", "product": "Phone", "quantity": 15, "unitprice": 44.01, "storelocation": "Store A", "customertype": "Retail", "salesperson": "Alice", "totalprice": 544.01, "paymentmethod": "Gift Card", "orderid": "REG100001", "manager": "Sophie"}', 'clean'),
(2, '{"date": "2023-05-10", "region": "North", "product": "Desk", "quantity": 14, "unitprice": 346.18, "storelocation": "Store B", "customertype": "Wholesale", "salesperson": "Alice", "totalprice": 4361.868, "paymentmethod": "Online", "orderid": "REG100002", "manager": "Ryan"}', 'clean');

-- C. DummyJSON Products API
INSERT INTO structured_records (source_id, record_data, status) VALUES
(3, '{"id": 1, "title": "Essence Mascara Lash Princess", "category": "beauty", "price": 9.99, "discountPercentage": 10.48, "rating": 2.56, "stock": 99, "brand": "Essence"}', 'clean'),
(3, '{"id": 2, "title": "Eyeshadow Palette with Mirror", "category": "beauty", "price": 19.99, "discountPercentage": 18.19, "rating": 2.86, "stock": 34, "brand": "Glamour Beauty"}', 'clean'),
(3, '{"id": 6, "title": "Calvin Klein CK One", "category": "fragrances", "price": 49.99, "discountPercentage": 1.89, "rating": 4.37, "stock": 29, "brand": "Calvin Klein"}', 'clean');

-- ==========================================
-- 7. INGESTION LOGS
-- ==========================================
INSERT INTO ingestion_logs (run_id, source_id, pipeline_run_id, source_type, status, records_read, records_valid, records_invalid) VALUES
('run_real_superstore', 1, 1, 'csv', 'success', 3, 3, 0),
('run_real_salesregion', 2, 1, 'xlsx', 'success', 3, 3, 0),
('run_real_dummyjson', 3, 1, 'api', 'success', 3, 3, 0),
('run_real_dataflow', 4, 1, 'pdf', 'success', 3, 3, 0);

-- ==========================================
-- 8. PREDICTION LOGS
-- ==========================================
INSERT INTO prediction_logs (source_id, structured_record_id, model_name, model_version, input_payload, prediction_result, predicted_label, confidence_score) VALUES
(1, 1, 'profit_anomaly_detector', 'v1.2', '{"Category": "Furniture", "Sales": 261.96, "Profit": 41.9136}', '{"is_anomaly": false}', 'Normal_Profit', 0.94),
(2, 4, 'sales_forecaster', 'v2.0', '{"product": "Laptop", "quantity": 14, "totalprice": 2290.4}', '{"forecast_next_quarter_sales": 2500.0}', 'High_Demand', 0.88);

-- ==========================================
-- 9. RAG QUERY LOGS
-- ==========================================
INSERT INTO rag_query_logs (document_id, user_query, retrieved_chunk_ids, retrieval_scores, generated_response, answer_confidence, latency_ms, model_name) VALUES
(3, 'What is the DataFlow framework?', '["doc_003_page_2_chunk_000"]', '[0.91]', 'DataFlow is an LLM-Driven Framework for Unified Data Preparation and Workflow Automation designed to handle scalable and semantically rich data pipelines.', 0.96, 1150, 'gpt-4o-mini');

-- 1. v_dashboard_overview (High-level system metrics)
CREATE OR REPLACE VIEW v_dashboard_overview AS
SELECT
    (SELECT COUNT(*) FROM sources) AS total_sources,
    (SELECT COUNT(*) FROM documents) AS total_documents,
    (SELECT COUNT(*) FROM ingestion_logs WHERE status = 'success') AS successful_ingestions,
    (SELECT COUNT(*) FROM ingestion_logs WHERE status = 'failed') AS failed_ingestions,
    (SELECT COUNT(*) FROM rag_query_logs) AS total_rag_queries,
    (SELECT COUNT(*) FROM prediction_logs) AS total_predictions;

-- 2. v_ingestion_health (Track ETL quality over time)
CREATE OR REPLACE VIEW v_ingestion_health AS
SELECT 
    DATE(created_at) AS ingestion_date,
    status,
    COUNT(*) AS run_count,
    SUM(records_read) AS total_read,
    SUM(records_valid) AS total_valid,
    SUM(records_invalid) AS total_invalid
FROM ingestion_logs
GROUP BY DATE(created_at), status
ORDER BY ingestion_date DESC;

-- 3. v_source_quality_summary (Track volume and error rates per source)
CREATE OR REPLACE VIEW v_source_quality_summary AS
SELECT 
    s.id AS source_id,
    s.name AS source_name,
    s.source_type,
    s.status,
    COUNT(DISTINCT d.id) AS total_documents,
    COUNT(DISTINCT sr.id) AS total_structured_records,
    COALESCE(SUM(il.records_invalid), 0) AS total_invalid_records
FROM sources s
LEFT JOIN documents d ON s.id = d.source_id
LEFT JOIN structured_records sr ON s.id = sr.source_id
LEFT JOIN ingestion_logs il ON s.id = il.source_id
GROUP BY s.id, s.name, s.source_type, s.status;

-- 4. v_document_quality_summary (Track processing status of unstructured data)
CREATE OR REPLACE VIEW v_document_quality_summary AS
SELECT 
    processing_status, 
    file_type,
    COUNT(*) AS document_count,
    COALESCE(AVG(page_count), 0) AS avg_page_count
FROM documents
GROUP BY processing_status, file_type;

-- 5. v_rag_daily_metrics (Track chatbot performance and confidence)
CREATE OR REPLACE VIEW v_rag_daily_metrics AS
SELECT 
    DATE(created_at) AS query_date,
    COUNT(*) AS total_queries,
    AVG(latency_ms) AS avg_latency_ms,
    AVG(answer_confidence) AS avg_confidence,
    model_name
FROM rag_query_logs
GROUP BY DATE(created_at), model_name
ORDER BY query_date DESC;

-- 6. v_prediction_confidence_summary (Track ML model outputs for review)
CREATE OR REPLACE VIEW v_prediction_confidence_summary AS
SELECT 
    model_name,
    model_version,
    predicted_label,
    COUNT(*) AS prediction_count,
    AVG(confidence_score) AS avg_confidence,
    MIN(confidence_score) AS min_confidence
FROM prediction_logs
GROUP BY model_name, model_version, predicted_label;

-- 7. v_recent_activity (Live feed for Streamlit dashboard)
CREATE OR REPLACE VIEW v_recent_activity AS
SELECT 
    'RAG Query' AS activity_type,
    user_query AS description,
    created_at
FROM rag_query_logs
UNION ALL
SELECT 
    'Ingestion Issue' AS activity_type,
    error_message AS description,
    created_at
FROM ingestion_logs
WHERE error_message IS NOT NULL AND status != 'success'
UNION ALL
SELECT 
    'New Source Added' AS activity_type,
    name AS description,
    created_at
FROM sources
ORDER BY created_at DESC
LIMIT 50;
