import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from app.routers.root import router


@pytest.fixture
def app():
    _app = FastAPI()
    _app.include_router(router)
    return _app


@pytest.fixture
def client(app):
    return TestClient(app)


def test_root_returns_welcome_message(client):
    response = client.get("/")
    assert response.status_code == 200
    assert "mycomponent" in response.text
