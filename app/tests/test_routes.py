import pytest
from app import create_app
from app.config import TestingConfig


@pytest.fixture
def client():
    app = create_app(TestingConfig)
    with app.test_client() as c:
        yield c


def test_health_returns_ok(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "ok"


def test_list_items_returns_list(client):
    response = client.get("/items")
    assert response.status_code == 200
    data = response.get_json()
    assert "items" in data
    assert data["count"] == len(data["items"])


def test_get_existing_item(client):
    response = client.get("/items/1")
    assert response.status_code == 200
    assert response.get_json()["id"] == "1"


def test_get_nonexistent_item_returns_404(client):
    response = client.get("/items/9999")
    assert response.status_code == 404


def test_invalid_item_id_returns_400(client):
    response = client.get("/items/../../etc/passwd")
    assert response.status_code in (400, 404)


def test_create_item_valid(client):
    response = client.post(
        "/items",
        json={"name": "Widget C", "category": "hardware"},
    )
    assert response.status_code == 201
    data = response.get_json()
    assert data["name"] == "Widget C"


def test_create_item_missing_name_returns_400(client):
    response = client.post("/items", json={"category": "hardware"})
    assert response.status_code == 400


def test_create_item_invalid_json_returns_400(client):
    response = client.post(
        "/items",
        data="not-json",
        content_type="application/json",
    )
    assert response.status_code == 400
