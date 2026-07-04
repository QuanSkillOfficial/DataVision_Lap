import sys
from pathlib import Path
import types

sys.path.append(str(Path(__file__).parent.parent.parent))

from ai.rag.vector_store import VectorStore


def test_vector_store_uses_database_url_from_environment(monkeypatch):
    captured = {}

    class DummyConnection:
        def cursor(self):
            raise RuntimeError("cursor should not be used in this test")

        def commit(self):
            pass

        def rollback(self):
            pass

    def fake_connect(connection_string):
        captured["connection_string"] = connection_string
        return DummyConnection()

    monkeypatch.setenv("DATABASE_URL", "postgresql://user:pass@localhost:5432/rag_db")
    monkeypatch.setattr(VectorStore, "_validate_existing_schema", lambda self: None)
    monkeypatch.setitem(sys.modules, "psycopg2", types.SimpleNamespace(connect=fake_connect))

    vector_store = VectorStore(use_pgvector=True)

    assert captured["connection_string"] == "postgresql://user:pass@localhost:5432/rag_db"
    assert vector_store.connection is not None
