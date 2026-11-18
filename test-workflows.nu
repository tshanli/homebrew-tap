#!/usr/bin/env nu

# Local checks for the update automation. Cross-platform Nushell.
#
#   nu test-workflows.nu          run the unit tests, then dry-run the workflow with act
#   nu test-workflows.nu --unit   run only the unit tests (no Docker, no act)

def main [--unit] {
  # Work from the repo root whatever the caller's directory is.
  cd ($env.CURRENT_FILE | path dirname)

  print "🧪 Unit tests (scripts/tests)"
  nu scripts/test.nu

  if $unit { return }

  if (which act | is-empty) {
    error make { msg: "act is not installed. Install it with: brew install act (or your package manager)" }
  }
  let docker = (do { docker info } | complete)
  if $docker.exit_code != 0 {
    error make { msg: "Docker is not running. Please start Docker Desktop." }
  }

  print "🧪 Dry run of .github/workflows/update.yml"
  ^act workflow_dispatch -n -W .github/workflows/update.yml --container-architecture linux/amd64
}
