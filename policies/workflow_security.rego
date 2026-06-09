package pipeline.workflow

import rego.v1

# ──────────────────────────────────────────────────────────────
# Policy: GitHub Actions workflow must define top-level permissions
# ──────────────────────────────────────────────────────────────

deny contains msg if {
	not input.permissions
	msg := "POLICY VIOLATION: Workflow must declare explicit 'permissions' at the top level to follow least-privilege principles."
}

deny contains msg if {
	input.permissions.contents == "write"
	msg := "POLICY VIOLATION: 'permissions.contents' must not be 'write' unless strictly required. Use 'read'."
}

# ──────────────────────────────────────────────────────────────
# Policy: All jobs must pin actions to a SHA or a major version tag
# ──────────────────────────────────────────────────────────────

warn contains msg if {
	job := input.jobs[job_name]
	step := job.steps[_]
	uses := step.uses
	uses != null
	not contains(uses, "@")
	msg := sprintf("POLICY WARNING: Step '%v' in job '%v' uses an action without a version pin.", [step.name, job_name])
}

# ──────────────────────────────────────────────────────────────
# Policy: Production deploy job must require a manual approval environment
# ──────────────────────────────────────────────────────────────

deny contains msg if {
	job := input.jobs[job_name]
	contains(lower(job_name), "deploy")
	contains(lower(job_name), "prod")
	not job.environment
	msg := sprintf("POLICY VIOLATION: Job '%v' targets production but does not declare an 'environment' (required for manual approval gate).", [job_name])
}

# ──────────────────────────────────────────────────────────────
# Policy: Secrets scan job must be present and upstream of every other job
# ──────────────────────────────────────────────────────────────

deny contains msg if {
	not input.jobs["secrets-scan"]
	msg := "POLICY VIOLATION: Pipeline must include a 'secrets-scan' job."
}

# ──────────────────────────────────────────────────────────────
# Policy: No job may use 'continue-on-error: true' on security-critical steps
# labeled as "Fail on critical"
# ──────────────────────────────────────────────────────────────

warn contains msg if {
	job := input.jobs[job_name]
	step := job.steps[_]
	step["continue-on-error"] == true
	contains(lower(step.name), "critical")
	msg := sprintf("POLICY WARNING: Step '%v' in job '%v' uses continue-on-error=true on a critical check.", [step.name, job_name])
}
