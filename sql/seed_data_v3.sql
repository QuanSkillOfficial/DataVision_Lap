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