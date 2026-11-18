#!/usr/bin/env nu

# Runs every `test-*` command in scripts/tests/*.nu, each in its own nu process.
# Usage: nu scripts/test.nu [filter]
def main [filter: string = ""] {
  let here = ($env.CURRENT_FILE | path dirname)
  let results = (
    glob ($here | path join "tests" "*.nu")
    | each {|file|
      open --raw $file
      | lines
      | parse --regex '^def (?<name>test-[\w-]+)'
      | get name
      | where {|n| $n | str contains $filter }
      | each {|name|
        let r = (^nu --no-config-file -c $"use std/assert; source '($file)'; ($name)" | complete)
        { test: $name, ok: ($r.exit_code == 0), output: ($r.stdout + $r.stderr | str trim) }
      }
    }
    | flatten
  )

  for r in $results {
    if $r.ok {
      print $"PASS ($r.test)"
    } else {
      print $"FAIL ($r.test)\n($r.output)"
    }
  }
  let failed = ($results | where not ok | length)
  print $"\n($results | length) tests, ($failed) failed"
  if $failed > 0 or ($results | is-empty) { exit 1 }
}
