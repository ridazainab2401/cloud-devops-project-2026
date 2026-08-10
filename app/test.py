import pytest
from app import app as flask_app

@pytest.fixture
def client():
    with flask_app.test_client() as client:
        yield client

def test_home_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b"Welcome to the Cloud DevOps Lab" in response.data

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert b"healthy" in response.data