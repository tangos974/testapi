from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_health():
    """Test the /health endpoint to ensure it returns a status code of 200
    and a JSON response with {"status": "ok"}."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_hello():
    """Test the /hello endpoint to ensure it returns a status code of 200
    and a JSON response with {"message": "Hello, World!"}."""
    response = client.get("/hello")
    assert response.status_code == 200
    assert "message" in response.json()
    assert response.json()["message"] == "Hello, World!"
