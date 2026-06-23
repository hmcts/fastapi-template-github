# fastapi-template-github

A GitHub template for HMCTS Python FastAPI microservices.

## Using this template

Click **"Use this template"** on GitHub, clone your new repo, then run the setup script:

```bash
bash bin/setup.sh
```

This will prompt for your product and component names and replace all placeholders throughout the repo (files and directory names).

| Placeholder | Replace with | Example |
|---|---|---|
| `myproduct` | Your product name | `cmc` |
| `mycomponent` | Your component name | `claim-store` |

## Running locally

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) then:

```bash
uv sync
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

| Endpoint | Purpose |
|---|---|
| `GET /health` | Checked by the Jenkins pipeline after deploy to confirm the service is up |
| `GET /health/readiness` | Return HTTP 200 when ready to receive traffic |
| `GET /health/liveness` | Return HTTP 200 when the process is alive |

## Running tests

```bash
uv run pytest tests/unit -v                              # unit tests
uv run pytest tests/unit -v --cov=app --cov-report=xml  # unit tests with coverage
uv run pytest tests/smoke -v                             # smoke tests (requires TEST_URL env var)
uv run pytest tests/functional -v                       # functional tests (requires TEST_URL env var)
```

## Security scanning

The Jenkins pipeline runs `uv audit` on every build to check for known vulnerabilities in dependencies. If vulnerabilities are found, the build fails and a `uv-audit-report.json` artifact is attached to the build with full details.

To run the audit locally:

```bash
uv audit
```

Fix vulnerabilities by upgrading the affected package:

```bash
uv lock --upgrade-package <package>
```

## Code quality

A `sonar-project.properties` file is included. SonarCloud analysis runs automatically in the Jenkins pipeline on every PR and merge to `master`. Coverage results from pytest are uploaded automatically — no manual configuration required.

## Application Insights

The service uses the [HMCTS Python base image](https://github.com/hmcts/cnp-python-base), which has Azure Application Insights pre-wired via OpenTelemetry — no application code changes are required.

### Environment variables

| Variable | Required | Description |
|---|---|---|
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | One of these two | The App Insights connection string directly. |
| `APPLICATIONINSIGHTS_CONNECTION_STRING_FILE` | One of these two | Path to a file containing the connection string (recommended for cluster deployments). |
| `OTEL_SERVICE_NAME` | Optional | Labels telemetry with the service name. Defaults to `unknown_service`. |
| `APPLICATIONINSIGHTS_LOGGER_NAMESPACE` | Optional | Logger namespace whose logs are forwarded to App Insights. Defaults to `uvicorn`. Set to `""` to capture all logs. |
| `OTEL_PYTHON_EXCLUDED_URLS` | Optional | Comma-separated URL patterns to exclude from tracing. Defaults to `health,readiness,liveness`. |

In HMCTS clusters, mount the connection string from Key Vault as a file and point `APPLICATIONINSIGHTS_CONNECTION_STRING_FILE` at it to keep the secret out of git.

Leave both connection string variables unset and telemetry is disabled — local development is unaffected.

For full details see the [cnp-python-base Application Insights documentation](https://github.com/hmcts/cnp-python-base#application-insights).

## Managing dependencies

Dependencies are managed with [uv](https://docs.astral.sh/uv/). The `uv.lock` file must always be committed — the Docker build uses `--frozen` and will fail if it is missing or out of sync.

### Adding a dependency

```bash
uv add <package>          # production dependency
uv add --dev <package>    # development-only dependency (not installed in Docker)
```

This updates both `pyproject.toml` and `uv.lock`. Commit both files.

### Updating dependencies

```bash
uv sync          # install/update to match uv.lock
uv lock --upgrade  # regenerate uv.lock with latest compatible versions
```

### Supply chain security

`pyproject.toml` sets `exclude-newer = "7 days"` in `[tool.uv]`, which automatically prevents packages released in the last 7 days from being pinned when generating or updating the lockfile. This applies to all `uv lock` and `uv add` runs without any extra flags.

`UV_MALWARE_CHECK=1` is set in the Dockerfile, enabling uv's built-in malware scanning during install.

## Database (PostgreSQL)

To enable PostgreSQL, uncomment the `postgresql` block in `charts/myproduct-mycomponent/values.yaml` and add your database config to the `environment` section.

## Jenkins

This template uses the HMCTS Jenkins shared library. Follow the [new component setup guide](https://hmcts.github.io/cloud-native-platform/new-component/github-repo.html) to register your service.
