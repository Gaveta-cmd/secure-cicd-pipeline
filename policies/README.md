# OPA / Conftest Policies

These Rego policies are enforced by [Conftest](https://www.conftest.dev/) in Stage 6 of the CI pipeline.

| Policy file | Package | What it enforces |
|---|---|---|
| `workflow_security.rego` | `pipeline.workflow` | Workflow permissions, action pinning, production approval gate, secrets-scan presence |
| `dependency_policy.rego` | `pipeline.dependencies` | Exact version pinning in requirements.txt, banned package list |
| `config_policy.rego` | `pipeline.config` | Minimum 80% pytest coverage threshold |

## Running locally

```bash
# Install conftest
brew install conftest   # macOS
# or download from https://www.conftest.dev/install/

# Test the workflow file
conftest test .github/workflows/security-pipeline.yml --policy policies/

# Test requirements
conftest test requirements.txt --policy policies/ --parser line
```
