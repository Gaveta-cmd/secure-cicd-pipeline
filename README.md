# CloudSecOps Pipeline

A production-grade secure CI/CD pipeline built on GitHub Actions, designed to enforce security controls at every stage of the software delivery lifecycle. The pipeline targets a Python/Flask API but the architecture is language-agnostic and can be adapted to any stack.

---

## Overview

Most CI pipelines treat security as an afterthought — a single scan bolted on at the end. This project takes the opposite approach: security is a first-class gate at every stage, and code cannot reach production unless it passes all controls. If any stage fails, the pipeline halts before the next one begins.

```
push / PR
    │
    ▼
[1] Secrets Scan (Gitleaks)
    │
    ├──────────────────────────────┐
    ▼                              ▼
[2] SAST                     [3] Dependency Scan
    Semgrep + Bandit               pip-audit (OSV)
    │                              │
    └──────────┬───────────────────┘
               │         ▼
               │    [5] IaC Scan
               │    Checkov + Trivy
               │         │
               ▼         ▼
          [4] Unit Tests (pytest ≥ 80% coverage)
               │
               ▼
          [6] Policy Gate (OPA / Conftest)
               │
               ▼
          [7] Security Summary (GitHub Step Summary)
               │
         (main branch only)
               ▼
          [8] Manual Approval Gate ← environment protection rule
               │
               ▼
          [9] Deploy to Production
```

---

## Security Controls

| Stage | Tool | What it catches |
|-------|------|-----------------|
| Secrets Scan | [Gitleaks](https://github.com/gitleaks/gitleaks) | Hard-coded API keys, tokens, passwords in commits and history |
| SAST — Ruleset | [Semgrep](https://semgrep.dev) | OWASP Top 10, Flask-specific vulnerabilities, insecure patterns |
| SAST — Deep | [Bandit](https://bandit.readthedocs.io) | Python security anti-patterns (subprocess injection, weak crypto, etc.) |
| Dependency Audit | [pip-audit](https://pypi.org/project/pip-audit/) | Known CVEs in third-party packages via OSV database |
| IaC Analysis | [Checkov](https://www.checkov.io) | Misconfigured GitHub Actions workflows and infrastructure files |
| Container/FS | [Trivy](https://trivy.dev) | CVEs in filesystem and OS packages |
| Policy-as-Code | [OPA / Conftest](https://www.conftest.dev) | Custom governance rules (version pinning, coverage thresholds, approval gates) |
| Approval Gate | GitHub Environments | Human sign-off required before any production deployment |

SARIF results from Bandit, Checkov, and Trivy are uploaded to GitHub Code Scanning, making findings visible in the Security tab of the repository.

---

## Threat Model (Summary)

| Threat | Control |
|--------|---------|
| Leaked credentials in source code | Gitleaks on every push, `.gitignore` blocks `.env` files |
| Vulnerable third-party library | pip-audit against OSV, blocks pipeline if patched version exists |
| Insecure code patterns (SQLi, path traversal, etc.) | Semgrep (OWASP Top 10 ruleset) + Bandit |
| Misconfigured workflow with excessive permissions | Checkov IaC scan + OPA policy enforcing `permissions: read` |
| Unauthorized production deployment | Manual approval environment gate, branch protection on `main` |
| Low test coverage masking bugs | OPA policy blocks deploy if pytest coverage < 80% |

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── security-pipeline.yml   # Full 9-stage pipeline definition
├── app/
│   ├── __init__.py                  # Flask application factory
│   ├── config.py                    # Environment-based configuration
│   ├── routes.py                    # API endpoints with input validation
│   └── tests/
│       └── test_routes.py           # pytest unit tests
├── policies/
│   ├── workflow_security.rego       # OPA: workflow governance rules
│   ├── dependency_policy.rego       # OPA: dependency pinning + banned packages
│   └── config_policy.rego           # OPA: pytest coverage threshold enforcement
├── main.py                          # Application entry point
├── requirements.txt                 # Production dependencies (exact versions)
├── requirements-dev.txt             # Dev/security tooling dependencies
├── pytest.ini                       # Test configuration with coverage gate
├── .env.example                     # Environment variable template (no real secrets)
└── .gitignore                       # Blocks secrets, build artifacts, reports
```

---

## Running Locally

**Prerequisites:** Python 3.12+, pip

```bash
# Clone and set up environment
git clone https://github.com/<your-username>/secure-cicd-pipeline
cd secure-cicd-pipeline
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt

# Copy env template
cp .env.example .env
# Edit .env with your local values

# Run the API
python main.py
# → http://localhost:5000/health

# Run unit tests
pytest

# Run SAST locally
bandit -r app/ --severity-level medium
semgrep --config p/python --config p/flask app/

# Audit dependencies
pip-audit -r requirements.txt

# Run OPA policies (requires conftest installed)
conftest test .github/workflows/security-pipeline.yml --policy policies/
```

---

## Pipeline Setup (GitHub)

1. **Fork / push** this repository to GitHub.
2. **Create a `production` environment** under *Settings → Environments* and add at least one required reviewer.
3. **Add repository secrets** (optional, for full functionality):
   - `SEMGREP_APP_TOKEN` — for Semgrep Cloud dashboard results
   - `GITLEAKS_LICENSE` — for Gitleaks Pro (free tier works without it)
4. Push to `main` or open a pull request — the pipeline triggers automatically.

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Liveness check |
| `GET` | `/items` | List all items |
| `GET` | `/items/<id>` | Get item by ID |
| `POST` | `/items` | Create a new item |

```bash
curl http://localhost:5000/health
# {"status": "ok", "version": "1.0.0"}

curl -X POST http://localhost:5000/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Widget C", "category": "hardware"}'
# {"id": "3", "name": "Widget C", "category": "hardware"}
```

---

## Key Design Decisions

**Parallel execution where safe.** Secrets scan runs first and gates everything. SAST, dependency scan, and IaC scan run in parallel after it, reducing total pipeline time. Unit tests and the policy gate run after all security scans complete.

**SARIF for everything.** Bandit, Checkov, and Trivy all emit SARIF, which GitHub ingests natively into Code Scanning. Findings are reviewable in pull requests without leaving GitHub.

**Policy-as-Code over ad-hoc scripts.** OPA/Rego policies are version-controlled, testable, and auditable. Adding a new governance rule is a code change with a code review, not a one-off shell script.

**No secrets in the pipeline.** `GITHUB_TOKEN` is the only token the pipeline uses by default, scoped to `contents: read`. Optional integrations (Semgrep Cloud) use secrets stored in GitHub, never in code.
