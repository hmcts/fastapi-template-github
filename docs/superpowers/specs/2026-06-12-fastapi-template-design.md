# FastAPI GitHub Template — Design

**Date:** 2026-06-12  
**Status:** Approved

## Overview

A GitHub template repository (`fastapi-template-github`) for scaffolding new HMCTS Python FastAPI microservices. Teams click "Use this template", clone the result, and find-and-replace the placeholder values `myproduct` and `mycomponent` to get a working, platform-compliant service.

Follows the same conventions as `spring-boot-template` for all HMCTS platform-required files (Dockerfile, Jenkinsfile, Helm chart, Backstage catalog, infrastructure), while using Python-idiomatic conventions for application and test code.

---

## Repository Structure

```
fastapi-template-github/
├── app/
│   ├── __init__.py
│   ├── main.py                        # FastAPI app, health endpoints, App Insights wiring
│   └── routers/
│       └── root.py                    # Example GET / endpoint
├── tests/
│   ├── unit/
│   │   └── test_root.py               # Unit tests using FastAPI TestClient
│   ├── smoke/
│   │   └── test_smoke.py              # Smoke test stub (reads TEST_URL from env)
│   └── functional/
│       └── test_functional.py         # Functional test stub
├── charts/
│   └── myproduct-mycomponent/
│       ├── Chart.yaml                 # Depends on chart-python from hmctsprod ACR
│       ├── values.yaml
│       ├── values.preview.template.yaml
│       └── values.aat.template.yaml
├── infrastructure/
│   └── main.tf                        # Terraform azurerm provider stub
├── Dockerfile                         # Multi-stage distroless build
├── Jenkinsfile_template               # withPipeline("python", "myproduct", "mycomponent")
├── Jenkinsfile_nightly                # Nightly pipeline stub
├── pyproject.toml                     # Runtime and dev dependencies
├── catalog-info.yaml                  # Backstage metadata
├── renovate.json                      # Inherits HMCTS shared Renovate config
├── .github/
│   ├── CODEOWNERS
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       ├── ci.yml                     # pytest on PR and push to main
│       └── codeql.yml                 # Python CodeQL analysis
└── README.md
```

---

## Application Code

### `app/main.py`
Creates the FastAPI app instance, includes the root and health routers, and exposes the two required HMCTS health endpoints:

- `GET /health/readiness` — returns `{"status": "UP"}`
- `GET /health/liveness` — returns `{"status": "UP"}`

Includes a commented-out Application Insights configuration block:

```python
# from azure.monitor.opentelemetry import configure_azure_monitor
# configure_azure_monitor()  # reads APPLICATIONINSIGHTS_CONNECTION_STRING from env
```

### `app/routers/root.py`
A single example endpoint:

```python
GET /  →  200 "Welcome to mycomponent"
```

Mirrors the `RootController` in the Java template. Teams replace or remove this as they build out their service.

### `pyproject.toml`
```toml
[project]
dependencies = [
    "fastapi",
    "uvicorn[standard]",
    # "azure-monitor-opentelemetry",  # Uncomment to enable Application Insights
]

[project.optional-dependencies]
dev = [
    "pytest",
    "pytest-asyncio",
    "httpx",
]
```

Port: **8000** (consistent with `chart-python` defaults).

---

## Tests

### Unit (`tests/unit/test_root.py`)
Uses FastAPI's `TestClient` (backed by `httpx`) to assert the root and health endpoints return 200. Runs with `pytest` locally and in CI.

### Smoke (`tests/smoke/test_smoke.py`)
Reads `TEST_URL` from the environment, makes an HTTP request to `/health/liveness`, asserts 200. Intended to run post-deployment via Jenkins.

### Functional (`tests/functional/test_functional.py`)
Minimal stub, same pattern as the smoke test. Teams add their own functional scenarios here.

---

## Dockerfile

Multi-stage build:

1. **Build stage** — `python:3.13-slim-trixie`: installs `gcc`/`libc6-dev` for C extension compilation, creates a venv, installs dependencies from `pyproject.toml`.
2. **Final stage** — `hmctsprod.azurecr.io/base/python:3.13-distroless` *(placeholder — base image to be created)*: copies only the venv and `app/` from the build stage.

```dockerfile
# renovate: datasource=docker depName=hmctsprod.azurecr.io/base/python
FROM python:3.13-slim-trixie AS build
RUN apt-get update && apt-get install --no-install-suggests --no-install-recommends --yes gcc libc6-dev && \
    ln -s /usr/local/bin/python /usr/bin/python && \
    /usr/bin/python -m venv /venv && \
    /venv/bin/pip install --upgrade pip setuptools wheel
COPY pyproject.toml .
RUN /venv/bin/pip install --disable-pip-version-check .

# TODO: Replace with real HMCTS Python base image once created
FROM hmctsprod.azurecr.io/base/python:3.13-distroless
COPY --from=build /venv /venv
COPY app/ /app/
WORKDIR /app
ENTRYPOINT ["/venv/bin/python3"]
CMD ["-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Platform Files

### Jenkins
**`Jenkinsfile_template`:**
```groovy
@Library("Infrastructure")
def type = "python"
def product = "myproduct"
def component = "mycomponent"
withPipeline(type, product, component) {}
```

**`Jenkinsfile_nightly`:** Same structure with a nightly trigger placeholder comment.

### Helm Chart (`charts/myproduct-mycomponent/`)
- `Chart.yaml` — depends on `chart-python` from `oci://hmctsprod.azurecr.io/helm`, pinned to latest released version at time of creation.
- `values.yaml` — sets `python.image`, `python.applicationPort: 8000`, `python.ingressHost`, and a commented-out `postgresql` block for teams that need a database.
- `values.preview.template.yaml` / `values.aat.template.yaml` — environment-specific overrides.

### Infrastructure (`infrastructure/main.tf`)
Minimal Terraform stub with `azurerm` provider block. Teams add their own resources here.

### Backstage (`catalog-info.yaml`)
```yaml
tags:
  - python
metadata:
  name: "myproduct-mycomponent"
```
Uses the same placeholder convention as the Java template.

### GitHub Workflows
- **`ci.yml`** — `actions/setup-python@v5` with Python 3.13, runs `pip install -e ".[dev]"` then `pytest tests/unit`.
- **`codeql.yml`** — CodeQL analysis with `language: python`, triggered on push/PR to main and weekly schedule.

---

## Placeholders for Teams to Replace

| Placeholder | Example replacement | Where used |
|---|---|---|
| `myproduct` | `cmc` | Jenkinsfile, Helm chart name, values, catalog-info |
| `mycomponent` | `claim-store` | Jenkinsfile, Helm chart name, values, catalog-info |
| `hmctsprod.azurecr.io/base/python:3.13-distroless` | Real base image path | Dockerfile |

---

## Out of Scope (Initial Version)

- Backstage scaffolder integration (teams use "Use this template" button)
- HMCTS Python base image creation (placeholder used; tracked separately)
- Smoke/functional test runner infrastructure (provided by Jenkins shared library)
