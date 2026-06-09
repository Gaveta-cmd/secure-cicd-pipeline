package pipeline.dependencies

import rego.v1

# ──────────────────────────────────────────────────────────────
# Policy: requirements.txt must pin exact versions
# Conftest passes the raw file lines as input when using --parser=line
# ──────────────────────────────────────────────────────────────

deny contains msg if {
	line := input[_]
	not startswith(line, "#")
	not startswith(line, "-r")
	line != ""
	not contains(line, "==")
	msg := sprintf("POLICY VIOLATION: Dependency '%v' must use '==' to pin an exact version.", [line])
}

# ──────────────────────────────────────────────────────────────
# Policy: Banned packages (known unsafe or deprecated)
# ──────────────────────────────────────────────────────────────

banned_packages := {"pycrypto", "md5", "sha", "insecure-package"}

deny contains msg if {
	line := input[_]
	not startswith(line, "#")
	pkg := lower(split(line, "==")[0])
	pkg_trimmed := trim_space(pkg)
	banned_packages[pkg_trimmed]
	msg := sprintf("POLICY VIOLATION: Package '%v' is banned. Use a secure alternative.", [pkg_trimmed])
}
