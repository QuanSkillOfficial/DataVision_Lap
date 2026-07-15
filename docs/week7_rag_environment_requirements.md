# Week 7 RAG Environment Requirements

**Author:** Lap (RAG / Vector Search Module Owner)
**Week:** 7
**Date:** July 2026

## Purpose

Document the environment requirements for running the RAG module in development, CI, and production.

## Python Requirements

### Python Version
- **Minimum**: Python 3.9
- **Recommended**: Python 3.10
- **Tested**: Python 3.9, 3.10, 3.11

### Core Dependencies

#### Required for All Environments

```txt
numpy>=1.21.0
scikit-learn>=1.0.0
sentence-transformers>=2.2.0
torch>=1.12.0
```

#### Required for Database Integration

```txt
psycopg2-binary>=2.9.0
```

#### Required for Testing

```txt
pytest>=7.0.0
pytest-cov>=3.0.0
```

#### Required for API (Week 8/9)

```txt
fastapi>=0.95.0
uvicorn>=0.22.0
pydantic>=2.0.0
```

### Optional Dependencies

#### For Development

```txt
ipython>=8.0.0
jupyter>=1.0.0
black>=23.0.0
flake8>=6.0.0
mypy>=1.0.0
```

#### For Monitoring (Future)

```txt
prometheus-client>=0.16.0
sentry-sdk>=1.0.0
```

## System Requirements

### CPU
- **Minimum**: 2 cores
- **Recommended**: 4 cores
- **For Production**: 8+ cores

### RAM
- **Minimum**: 4 GB
- **Recommended**: 8 GB
- **For Production**: 16+ GB

### Disk
- **Minimum**: 10 GB free
- **Recommended**: 20 GB free
- **For Production**: 50+ GB free

### GPU
- **Required**: No (CPU inference supported)
- **Optional**: NVIDIA GPU for faster embedding generation
- **CUDA**: 11.8+ (if using GPU)

## Database Requirements

### PostgreSQL
- **Version**: PostgreSQL 14+
- **Extension**: pgvector (required for vector similarity search)
- **Schema**: schema_v4 (documents, document_chunks, rag_query_logs)

### Database Connection
- **Protocol**: PostgreSQL
- **Port**: 5432 (default)
- **Connection Pooling**: Recommended for production
- **SSL**: Recommended for production

### pgvector Installation

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### Schema Requirements

#### documents table
```sql
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    document_external_id TEXT UNIQUE NOT NULL,
    file_name TEXT NOT NULL,
    page_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### document_chunks table
```sql
CREATE TABLE document_chunks (
    chunk_id TEXT PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id),
    chunk_text TEXT NOT NULL,
    embedding vector(384),
    chunk_metadata JSONB,
    page_number INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### rag_query_logs table
```sql
CREATE TABLE rag_query_logs (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id),
    query_text TEXT NOT NULL,
    retrieved_chunk_ids TEXT[],
    retrieval_scores FLOAT[],
    top_k INTEGER,
    latency_ms INTEGER,
    status TEXT,
    model_name TEXT,
    embedding_dimension INTEGER,
    generated_response TEXT,
    answer_confidence FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Environment Variables

### Required for Database Integration

```bash
# Database connection string
DATABASE_URL=postgresql://user:password@localhost:5432/datavision
# or
POSTGRES_URL=postgresql://user:password@localhost:5432/datavision
```

### Optional for Configuration

```bash
# Embedding model path (if using local model)
EMBEDDING_MODEL_PATH=/path/to/model

# Chunking parameters
CHUNK_SIZE=512
CHUNK_OVERLAP=50

# Retrieval parameters
TOP_K=5
MIN_SCORE=0.0

# API configuration (Week 8/9)
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4
```

### Optional for Monitoring

```bash
# Sentry for error tracking
SENTRY_DSN=https://your-sentry-dsn

# Prometheus metrics
METRICS_PORT=9090
```

## Installation Instructions

### Development Environment

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install in development mode
pip install -e .
```

### CI Environment

```bash
# Install dependencies
pip install pytest numpy scikit-learn

# Install package
pip install -e .
```

### Production Environment

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install production dependencies
pip install -r requirements-prod.txt

# Install package
pip install -e .
```

## Requirements Files

### requirements.txt (All Environments)

```txt
numpy>=1.21.0
scikit-learn>=1.0.0
sentence-transformers>=2.2.0
torch>=1.12.0
psycopg2-binary>=2.9.0
```

### requirements-dev.txt (Development)

```txt
-r requirements.txt
pytest>=7.0.0
pytest-cov>=3.0.0
ipython>=8.0.0
jupyter>=1.0.0
black>=23.0.0
flake8>=6.0.0
mypy>=1.0.0
```

### requirements-prod.txt (Production)

```txt
-r requirements.txt
fastapi>=0.95.0
uvicorn>=0.22.0
pydantic>=2.0.0
gunicorn>=21.0.0
```

### requirements-ci.txt (CI)

```txt
pytest>=7.0.0
numpy>=1.21.0
scikit-learn>=1.0.0
```

## Model Requirements

### Embedding Model

**Model**: sentence-transformers/all-MiniLM-L6-v2

**Download**: Automatic on first use via sentence-transformers

**Size**: ~90 MB

**Dimension**: 384

**Cache Location**: `~/.cache/torch/sentence_transformers/`

**Alternative**: Pre-download and cache for offline environments

### Model Download (Optional Pre-download)

```python
from sentence_transformers import SentenceTransformer

# Download and cache model
model = SentenceTransformer('all-MiniLM-L6-v2')
print(f"Model loaded from: {model._target_device}")
```

## Docker Requirements

### Dockerfile

```dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements-prod.txt .
RUN pip install --no-cache-dir -r requirements-prod.txt

# Copy application
COPY . .

# Install package
RUN pip install -e .

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "ai.rag.api:app", "--host", "0.0.0.0", "--port", "8000"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  rag-api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/datavision
    depends_on:
      - postgres

  postgres:
    image: pgvector/pgvector:pg16
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=datavision
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Operating System Requirements

### Supported Operating Systems
- **Linux**: Ubuntu 20.04+, Debian 11+, CentOS 8+
- **macOS**: macOS 11+ (Big Sur)
- **Windows**: Windows 10+ (with WSL2 recommended)

### Linux Requirements
- **glibc**: 2.28+
- **Python**: 3.9+ (via package manager or pyenv)

### macOS Requirements
- **Xcode Command Line Tools**: Required for some Python packages
- **Homebrew**: Recommended for package management

### Windows Requirements
- **WSL2**: Recommended for better compatibility
- **Visual C++ Build Tools**: Required for some Python packages

## Network Requirements

### Outbound Connections
- **Hugging Face**: Required for downloading sentence-transformers model
- **PyPI**: Required for downloading Python packages
- **PostgreSQL**: Required for database connection

### Inbound Connections (API)
- **Port**: 8000 (configurable)
- **Protocol**: HTTP/HTTPS
- **Firewall**: Allow inbound traffic on API port

### Bandwidth
- **Minimum**: 10 Mbps
- **Recommended**: 100 Mbps
- **For Production**: 1 Gbps+

## Security Requirements

### Database Security
- **SSL/TLS**: Required for production database connections
- **Password**: Strong password for database user
- **User Permissions**: Principle of least privilege
- **Connection Pooling**: Use connection pooling to limit connections

### API Security (Week 8/9)
- **Authentication**: API key or JWT
- **HTTPS**: Required for production API
- **Rate Limiting**: Implement rate limiting
- **Input Validation**: Validate all user inputs
- **SQL Injection**: Use parameterized queries

### Environment Variable Security
- **Never commit**: Do not commit .env files to version control
- **Use secrets**: Use secret management in production
- **Rotate keys**: Regularly rotate API keys and passwords

## Monitoring Requirements

### Logging
- **Level**: INFO for production, DEBUG for development
- **Format**: JSON for production, text for development
- **Destination**: stdout/stderr (containerized), log files (non-containerized)

### Metrics (Future)
- **Prometheus**: For metrics collection
- **Grafana**: For metrics visualization
- **Alerting**: For alerting on failures

### Error Tracking (Future)
- **Sentry**: For error tracking and alerting
- **Slack**: For critical error notifications

## Backup Requirements

### Database Backups
- **Frequency**: Daily for production
- **Retention**: 30 days
- **Method**: pg_dump or continuous archiving

### Model Backups
- **Cache**: Model is cached locally
- **Version**: Pin model version in requirements.txt
- **Redundancy**: Pre-download for offline environments

## Performance Requirements

### Latency Targets
- **Embedding Generation**: < 100ms per chunk
- **Retrieval**: < 50ms for top-5
- **End-to-End**: < 200ms for retrieval-only

### Throughput Targets
- **Retrieval**: 100+ queries/second
- **Ingestion**: 10+ documents/minute
- **API**: 1000+ requests/minute (with caching)

### Scalability
- **Horizontal**: Scale API instances behind load balancer
- **Vertical**: Increase CPU/RAM for embedding generation
- **Database**: Use connection pooling and read replicas

## Compliance Requirements

### Data Privacy
- **PII**: Do not store PII in document_chunks
- **GDPR**: Ensure compliance if processing EU data
- **Access Control**: Implement role-based access control

### Audit Logging
- **Query Logs**: Log all RAG queries to rag_query_logs
- **Access Logs**: Log API access for security
- **Retention**: 90 days for audit logs

## Troubleshooting

### Common Issues

#### Issue: psycopg2 installation fails
```bash
# Solution: Install system dependencies
sudo apt-get install libpq-dev  # Linux
brew install postgresql  # macOS
```

#### Issue: torch installation fails
```bash
# Solution: Install CPU-only version
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

#### Issue: Model download fails
```bash
# Solution: Set Hugging Face mirror (if in China)
export HF_ENDPOINT=https://hf-mirror.com
```

#### Issue: Out of memory during embedding generation
```bash
# Solution: Reduce batch size or increase RAM
# Process documents in smaller batches
```

## Week 7 Status

**Status**: Requirements documented

**Implementation**: Ready for environment setup

**Testing**: Pending environment validation

**Documentation**: Complete

## Next Steps

1. Create requirements.txt files for each environment
2. Set up development environment
3. Validate database schema
4. Test model download and caching
5. Configure environment variables
6. Set up Docker environment (optional)
