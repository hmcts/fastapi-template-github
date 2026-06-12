# FastAPI Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a GitHub template repository for scaffolding HMCTS Python FastAPI microservices, mirroring the conventions of `spring-boot-template`.

**Architecture:** Platform files (Dockerfile, Jenkinsfile, Helm chart, catalog-info) mirror the Java template structure and locations. Application code follows Python conventions — `app/` for the FastAPI service, `tests/` with `unit/`, `smoke/`, and `functional/` subdirectories, `pyproject.toml` for dependency management.

**Tech Stack:** Python 3.13, FastAPI, uvicorn, pytest, pytest-asyncio, httpx, Helm (chart-python), Jenkins shared library, GitHub Actions, Terraform (azurerm stub)

---

## File Map

| File | Purpose |
|------|---------|
| `pyproject.toml` | Runtime and dev dependencies |
| `app/__init__.py` | Package marker |
| `app/main.py` | FastAPI app instance, health endpoints, App Insights stub |
| `app/routers/__init__.py` | Package marker |
| `app/routers/root.py` | Example `GET /` endpoint |
| `tests/__init__.py` | Package marker |
| `tests/unit/__init__.py` | Package marker |
| `tests/unit/test_root.py` | Unit tests for all endpoints using TestClient |
| `tests/smoke/__init__.py` | Package marker |
| `tests/smoke/test_smoke.py` | Smoke test — hits `/health/liveness` against `TEST_URL` |
| `tests/functional/__init__.py` | Package marker |
| `tests/functional/test_functional.py` | Functional test stub — hits `GET /` against `TEST_URL` |
| `Dockerfile` | Multi-stage distroless build |
| `charts/myproduct-mycomponent/Chart.yaml` | Helm chart depending on chart-python |
| `charts/myproduct-mycomponent/values.yaml` | Default Helm values |
| `charts/myproduct-mycomponent/values.preview.template.yaml` | Preview env override |
| `charts/myproduct-mycomponent/values.aat.template.yaml` | AAT env override |
| `infrastructure/main.tf` | Terraform azurerm provider stub |
| `Jenkinsfile_template` | Jenkins pipeline: `withPipeline("python", ...)` |
| `Jenkinsfile_nightly` | Jenkins nightly pipeline stub |
| `catalog-info.yaml` | Backstage service metadata |
| `.github/renovate.json` | Inherits HMCTS shared Renovate config |
| `.github/CODEOWNERS` | Code ownership |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR checklist |
| `.github/workflows/ci.yml` | Run pytest on PR/push |
| `.github/workflows/codeql.yml` | Python CodeQL analysis |
| `.gitignore` | Python, IDE, and OS ignores |
| `README.md` | Usage instructions and placeholder replacement guide |

---

## Task 1: Project Foundation

**Files:**
- Create: `pyproject.toml`
- Create: `.gitignore`

- [ ] **Step 1: Create `pyproject.toml`**

```toml
[build-system]
requires = ["setuptools"]
build-backend = "setuptools.build_meta"

[project]
name = "myproduct-mycomponent"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.34.0",
    # "azure-monitor-opentelemetry",  # Uncomment to enable Application Insights
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.24.0",
    "httpx>=0.27.0",
]

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

- [ ] **Step 2: Create `.gitignore`**

```
# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd
.Python
*.egg-info/
dist/
build/
.venv/
venv/
*.egg

# Testing
.pytest_cache/
.coverage
htmlcov/

# IDE
.idea/
.vscode/
*.iml
*.iws
*.ipr

# OS
.DS_Store
```

- [ ] **Step 3: Install dependencies locally**

```bash
pip install -e ".[dev]"
```

Expected: packages install without errors.

- [ ] **Step 4: Commit**

```bash
git add pyproject.toml .gitignore
git commit -m "chore: add project foundation — pyproject.toml and .gitignore"
```

---

## Task 2: Root Router (TDD)

**Files:**
- Create: `app/__init__.py`
- Create: `app/routers/__init__.py`
- Create: `app/routers/root.py`
- Create: `tests/__init__.py`
- Create: `tests/unit/__init__.py`
- Create: `tests/unit/test_root.py` (written first)

- [ ] **Step 1: Create empty package markers**

Create four empty files:
- `app/__init__.py` — empty
- `app/routers/__init__.py` — empty
- `tests/__init__.py` — empty
- `tests/unit/__init__.py` — empty

- [ ] **Step 2: Write the failing test for the root endpoint**

Create `tests/unit/test_root.py`:

```python
from fastapi.testclient import TestClient


def test_root_returns_welcome_message(client):
    response = client.get("/")
    assert response.status_code == 200
    assert "mycomponent" in response.text
```

- [ ] **Step 3: Run test to verify it fails**

```bash
pytest tests/unit/test_root.py::test_root_returns_welcome_message -v
```

Expected: ERROR — `client` fixture not defined.

- [ ] **Step 4: Create `app/routers/root.py`**

```python
from fastapi import APIRouter
from fastapi.responses import PlainTextResponse

router = APIRouter()


@router.get("/", response_class=PlainTextResponse)
async def welcome() -> str:
    return "Welcome to mycomponent"
```

- [ ] **Step 5: Add the `client` fixture and import to the test**

Update `tests/unit/test_root.py`:

```python
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
```

- [ ] **Step 6: Run test to verify it passes**

```bash
pytest tests/unit/test_root.py::test_root_returns_welcome_message -v
```

Expected: PASSED

- [ ] **Step 7: Commit**

```bash
git add app/ tests/
git commit -m "feat: add root router with welcome endpoint"
```

---

## Task 3: FastAPI App with Health Endpoints (TDD)

**Files:**
- Create: `app/main.py`
- Modify: `tests/unit/test_root.py`

- [ ] **Step 1: Write failing tests for health endpoints**

Add to `tests/unit/test_root.py` (replace the entire file — use the full app, not just the router):

```python
import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from app.main import app
    return TestClient(app)


def test_root_returns_welcome_message(client):
    response = client.get("/")
    assert response.status_code == 200
    assert "mycomponent" in response.text


def test_readiness_returns_up(client):
    response = client.get("/health/readiness")
    assert response.status_code == 200
    assert response.json() == {"status": "UP"}


def test_liveness_returns_up(client):
    response = client.get("/health/liveness")
    assert response.status_code == 200
    assert response.json() == {"status": "UP"}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/unit/ -v
```

Expected: ERROR — `app.main` does not exist yet.

- [ ] **Step 3: Create `app/main.py`**

```python
from fastapi import FastAPI
from app.routers import root

# Uncomment to enable Azure Application Insights telemetry.
# Requires APPLICATIONINSIGHTS_CONNECTION_STRING environment variable.
# from azure.monitor.opentelemetry import configure_azure_monitor
# configure_azure_monitor()

app = FastAPI(title="mycomponent")

app.include_router(root.router)


@app.get("/health/readiness")
async def readiness() -> dict:
    return {"status": "UP"}


@app.get("/health/liveness")
async def liveness() -> dict:
    return {"status": "UP"}
```

- [ ] **Step 4: Run tests to verify they all pass**

```bash
pytest tests/unit/ -v
```

Expected: 3 tests PASSED.

- [ ] **Step 5: Commit**

```bash
git add app/main.py tests/unit/test_root.py
git commit -m "feat: add FastAPI app with health endpoints"
```

---

## Task 4: Smoke and Functional Test Stubs

**Files:**
- Create: `tests/smoke/__init__.py`
- Create: `tests/smoke/test_smoke.py`
- Create: `tests/functional/__init__.py`
- Create: `tests/functional/test_functional.py`

- [ ] **Step 1: Create empty package markers**

Create two empty files:
- `tests/smoke/__init__.py` — empty
- `tests/functional/__init__.py` — empty

- [ ] **Step 2: Create `tests/smoke/test_smoke.py`**

```python
import os
import httpx

TEST_URL = os.environ.get("TEST_URL", "http://localhost:8000")


def test_service_is_healthy():
    response = httpx.get(f"{TEST_URL}/health/liveness")
    assert response.status_code == 200
    assert response.json() == {"status": "UP"}
```

- [ ] **Step 3: Create `tests/functional/test_functional.py`**

```python
import os
import httpx

TEST_URL = os.environ.get("TEST_URL", "http://localhost:8000")


def test_root_endpoint_is_reachable():
    response = httpx.get(f"{TEST_URL}/")
    assert response.status_code == 200
```

- [ ] **Step 4: Run unit tests to confirm nothing broken**

```bash
pytest tests/unit/ -v
```

Expected: 3 tests PASSED.

- [ ] **Step 5: Commit**

```bash
git add tests/smoke/ tests/functional/
git commit -m "feat: add smoke and functional test stubs"
```

---

## Task 5: Dockerfile

**Files:**
- Create: `Dockerfile`

- [ ] **Step 1: Create `Dockerfile`**

```dockerfile
# renovate: datasource=docker depName=python
FROM python:3.13-slim-trixie AS build
RUN apt-get update && \
    apt-get install --no-install-suggests --no-install-recommends --yes gcc libc6-dev && \
    ln -s /usr/local/bin/python /usr/bin/python && \
    /usr/bin/python -m venv /venv && \
    /venv/bin/pip install --upgrade pip setuptools wheel

COPY pyproject.toml .
RUN /venv/bin/pip install --disable-pip-version-check .

# TODO: Replace with real HMCTS Python base image once created
# renovate: datasource=docker depName=hmctsprod.azurecr.io/base/python
FROM hmctsprod.azurecr.io/base/python:3.13-distroless
COPY --from=build /venv /venv
COPY app/ /app/
WORKDIR /app
ENTRYPOINT ["/venv/bin/python3"]
CMD ["-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 2: Verify it builds locally (optional — requires ACR access for final stage)**

To test the build stage only:

```bash
docker build --target build -t mycomponent-build .
```

Expected: build stage completes successfully.

- [ ] **Step 3: Commit**

```bash
git add Dockerfile
git commit -m "feat: add multi-stage distroless Dockerfile"
```

---

## Task 6: Helm Chart

**Files:**
- Create: `charts/myproduct-mycomponent/Chart.yaml`
- Create: `charts/myproduct-mycomponent/values.yaml`
- Create: `charts/myproduct-mycomponent/values.preview.template.yaml`
- Create: `charts/myproduct-mycomponent/values.aat.template.yaml`

- [ ] **Step 1: Create `charts/myproduct-mycomponent/Chart.yaml`**

```yaml
apiVersion: v2
appVersion: "1.0"
description: A Helm chart for mycomponent
name: myproduct-mycomponent
home: https://github.com/hmcts/fastapi-template-github
version: 0.0.1
maintainers:
  - name: HMCTS myproduct team
dependencies:
  - name: python
    version: 0.1.0
    repository: 'oci://hmctsprod.azurecr.io/helm'
```

- [ ] **Step 2: Create `charts/myproduct-mycomponent/values.yaml`**

```yaml
python:
  applicationPort: 8000
  image: 'hmctsprod.azurecr.io/myproduct/mycomponent:latest'
  ingressHost: myproduct-mycomponent-{{ .Values.global.environment }}.service.core-compute-{{ .Values.global.environment }}.internal
  environment:
  # keyVaults:
  #   myproduct:
  #     secrets:
  #       - name: AppInsightsConnectionString
  #         alias: APPLICATIONINSIGHTS_CONNECTION_STRING
  # postgresql:
  #   enabled: true
```

- [ ] **Step 3: Create `charts/myproduct-mycomponent/values.preview.template.yaml`**

```yaml
python:
  # Don't modify below here
  image: ${IMAGE_NAME}
  ingressHost: ${SERVICE_FQDN}
```

- [ ] **Step 4: Create `charts/myproduct-mycomponent/values.aat.template.yaml`**

```yaml
# Don't modify this file, it is only needed for the pipeline to set the image and ingressHost
python:
  image: ${IMAGE_NAME}
  ingressHost: ${SERVICE_FQDN}
```

- [ ] **Step 5: Commit**

```bash
git add charts/
git commit -m "feat: add Helm chart using chart-python"
```

---

## Task 7: Jenkins Pipelines

**Files:**
- Create: `Jenkinsfile_template`
- Create: `Jenkinsfile_nightly`

- [ ] **Step 1: Create `Jenkinsfile_template`**

```groovy
#!groovy
// If this is a new microservice built on the template and you want it to run in Jenkins, you
// will need to follow these steps: https://hmcts.github.io/cloud-native-platform/new-component/github-repo.html

@Library("Infrastructure")

def type = "python"
def product = "myproduct"
def component = "mycomponent"

withPipeline(type, product, component) {}
```

- [ ] **Step 2: Create `Jenkinsfile_nightly`**

```groovy
#!groovy

properties([
  // H allow predefined but random minute see https://en.wikipedia.org/wiki/Cron#Non-standard_characters
  pipelineTriggers([cron('H 07 * * 1-5')])
])

@Library("Infrastructure")

def type = "python"
def product = "myproduct"
def component = "mycomponent"

withNightlyPipeline(type, product, component) {}
```

- [ ] **Step 3: Commit**

```bash
git add Jenkinsfile_template Jenkinsfile_nightly
git commit -m "feat: add Jenkins pipeline files"
```

---

## Task 8: GitHub Workflows

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/codeql.yml`

- [ ] **Step 1: Create `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.13'
      - name: Install dependencies
        run: pip install -e ".[dev]"
      - name: Run unit tests
        run: pytest tests/unit -v
```

- [ ] **Step 2: Create `.github/workflows/codeql.yml`**

```yaml
name: "CodeQL"

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]
  schedule:
    - cron: '36 5 * * 4'

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: python
      - uses: github/codeql-action/analyze@v3
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/
git commit -m "feat: add CI and CodeQL GitHub Actions workflows"
```

---

## Task 9: Repository Metadata

**Files:**
- Create: `.github/renovate.json`
- Create: `.github/CODEOWNERS`
- Create: `.github/PULL_REQUEST_TEMPLATE.md`
- Create: `infrastructure/main.tf`
- Create: `catalog-info.yaml`

- [ ] **Step 1: Create `.github/renovate.json`**

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "local>hmcts/.github:renovate-config",
    "local>hmcts/.github//renovate/automerge-all"
  ]
}
```

- [ ] **Step 2: Create `.github/CODEOWNERS`**

```
* @hmcts/platform-operations @hmcts/developer-enablement

# Ignore files updated by Renovate
Dockerfile
pyproject.toml
charts/**/Chart.yaml
.github/workflows/*.yml
```

- [ ] **Step 3: Create `.github/PULL_REQUEST_TEMPLATE.md`**

```markdown
**Before creating a pull request make sure that:**

- [ ] commit messages are meaningful and follow good commit message guidelines
- [ ] README and other documentation has been updated / added (if needed)
- [ ] tests have been updated / new tests have been added (if needed)

Please remove this line and everything above and fill the following sections:


### JIRA link (if applicable) ###



### Change description ###



**Does this PR introduce a breaking change?** (check one with "x")

```
[ ] Yes
[ ] No
```
```

- [ ] **Step 4: Create `infrastructure/main.tf`**

```hcl
provider "azurerm" {
  features {}
}
```

- [ ] **Step 5: Create `catalog-info.yaml`**

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: "myproduct-mycomponent"
  description: "mycomponent service"
  annotations:
    jenkins.io/job-full-name: cft:HMCTS_myproduct/fastapi-template-github
    github.com/project-slug: 'hmcts/fastapi-template-github'
  tags:
    - python
  links:
    - url: https://hmcts-reform.slack.com/app_redirect?channel=your-slack-channel
      title: your-slack-channel on Slack
      icon: chat
spec:
  type: service
  system: myproduct
  lifecycle: experimental
  owner: "team-name"
```

- [ ] **Step 6: Commit**

```bash
git add .github/renovate.json .github/CODEOWNERS .github/PULL_REQUEST_TEMPLATE.md infrastructure/ catalog-info.yaml
git commit -m "chore: add repository metadata, infrastructure stub and Backstage catalog"
```

---

## Task 10: README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create `README.md`**

```markdown
# fastapi-template-github

A GitHub template for HMCTS Python FastAPI microservices.

## Using this template

Click **"Use this template"** on GitHub, then find-and-replace the following placeholders throughout the repo:

| Placeholder | Replace with | Example |
|---|---|---|
| `myproduct` | Your product name | `cmc` |
| `mycomponent` | Your component name | `claim-store` |
| `hmctsprod.azurecr.io/base/python:3.13-distroless` | Real HMCTS Python base image | *(pending — check with platform team)* |

## Running locally

```bash
pip install -e ".[dev]"
uvicorn app.main:app --reload
```

The service will be available at `http://localhost:8000`.

## Health endpoints

Your service must expose:

- `GET /health/readiness` — return HTTP 200 when ready to receive traffic
- `GET /health/liveness` — return HTTP 200 when the process is alive

## Running tests

```bash
pytest tests/unit -v
```

## Application Insights

To enable Azure Application Insights telemetry, uncomment the two lines in `app/main.py` and add `azure-monitor-opentelemetry` to `pyproject.toml`. Set the `APPLICATIONINSIGHTS_CONNECTION_STRING` environment variable at runtime.

## Database (PostgreSQL)

To enable PostgreSQL, uncomment the `postgresql` block in `charts/myproduct-mycomponent/values.yaml` and add your database config to the `environment` section.

## Jenkins

This template uses the HMCTS Jenkins shared library. Follow the [new component setup guide](https://hmcts.github.io/cloud-native-platform/new-component/github-repo.html) to register your service.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with usage instructions"
```

---

## Task 11: Final Verification

- [ ] **Step 1: Run all unit tests**

```bash
pytest tests/unit/ -v
```

Expected output:
```
tests/unit/test_root.py::test_root_returns_welcome_message PASSED
tests/unit/test_root.py::test_readiness_returns_up PASSED
tests/unit/test_root.py::test_liveness_returns_up PASSED
3 passed
```

- [ ] **Step 2: Verify the app starts**

```bash
uvicorn app.main:app --port 8000
```

In another terminal:
```bash
curl http://localhost:8000/health/readiness
curl http://localhost:8000/health/liveness
curl http://localhost:8000/
```

Expected:
```
{"status":"UP"}
{"status":"UP"}
Welcome to mycomponent
```

- [ ] **Step 3: Verify repo structure matches spec**

```bash
find . -not -path './.git/*' -not -path './.venv/*' | sort
```

Confirm all files from the File Map above are present.

- [ ] **Step 4: Final commit if any loose files**

```bash
git status
# If clean, nothing to do. If any files remain unstaged:
git add -A
git commit -m "chore: final tidy-up"
```
