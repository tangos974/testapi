from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ip():
    response = client.get("/ip")
    assert response.status_code == 200
    assert "ip_address" in response.json()
