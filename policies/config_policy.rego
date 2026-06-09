package pipeline.config

import rego.v1

# ──────────────────────────────────────────────────────────────
# Policy: pytest must enforce a minimum coverage threshold
# Input: pytest.ini parsed as INI (Conftest parses INI as a map)
# ──────────────────────────────────────────────────────────────

deny contains msg if {
	addopts := input.pytest.addopts
	not contains(addopts, "--cov-fail-under")
	msg := "POLICY VIOLATION: pytest config must include '--cov-fail-under' to enforce a minimum code coverage threshold."
}

deny contains msg if {
	addopts := input.pytest.addopts
	contains(addopts, "--cov-fail-under=")
	threshold_str := regex.find_all_string_submatch_n(`--cov-fail-under=(\d+)`, addopts, 1)[0][1]
	to_number(threshold_str) < 80
	msg := sprintf("POLICY VIOLATION: Coverage threshold is %v%%. Minimum allowed is 80%%.", [threshold_str])
}
