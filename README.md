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

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) then:

```bash
uv sync --extra dev
uv run uvicorn app.main:app --reload
```

The service will be available at `http://localhost:8000`.

## Running locally via Docker

> **Note:** The Dockerfile uses an HMCTS internal base image from `hmctsprod.azurecr.io`. You must be logged in to the registry (`az acr login --name hmctsprod`) before building.

```bash
docker build -t mycomponent .
docker run -p 8000:8000 mycomponent
```

The service will be available at `http://localhost:8000`.

## Health endpoints

Your service must expose:

- `GET /health/readiness` — return HTTP 200 when ready to receive traffic
- `GET /health/liveness` — return HTTP 200 when the process is alive

## Running tests

```bash
uv run pytest tests/unit -v          # unit tests
uv run pytest tests/smoke -v         # smoke tests (requires TEST_URL env var)
uv run pytest tests/functional -v    # functional tests (requires TEST_URL env var)
```

## Application Insights

To enable Azure Application Insights telemetry, uncomment the two lines in `app/main.py` and add `azure-monitor-opentelemetry` to `pyproject.toml`. Set the `APPLICATIONINSIGHTS_CONNECTION_STRING` environment variable at runtime.

## Database (PostgreSQL)

To enable PostgreSQL, uncomment the `postgresql` block in `charts/myproduct-mycomponent/values.yaml` and add your database config to the `environment` section.

## Jenkins

This template uses the HMCTS Jenkins shared library. Follow the [new component setup guide](https://hmcts.github.io/cloud-native-platform/new-component/github-repo.html) to register your service.
