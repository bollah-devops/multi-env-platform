import pytest
from app.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_home_page(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Welcome" in response.data


def test_about_page(client):
    response = client.get("/about")
    assert response.status_code == 200
    assert b"About" in response.data


def test_api_status(client):
    response = client.get("/api/status")
    assert response.status_code == 200

    data = response.get_json()
    assert data["status"] == "ok"
    assert "environment" in data
    assert "version" in data