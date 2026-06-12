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
