#!/usr/bin/env nu

# Updates this tap's Packages from their Upstreams. See GLOSSARY.md.

# Group 3 is the quoted value; replacing with `${1}${2}new${2}` swaps it.
const version_line = '^(\s*version\s+)(["\x27])([^"\x27]*)["\x27]'
const commit_line = '^(\s*commit_hash\s*=\s*)(["\x27])([^"\x27]*)["\x27]'
const sha_line = '^\s*sha256\s+"[0-9a-f]{64}"'

# The `url` lines of a Formula or Cask, with `#{version}` replaced by `version`.
# Errors on any other Ruby interpolation: the URL must be derivable without Ruby.
export def expand-urls [text: string, version: string]: nothing -> list<string> {
  $text
  | lines
  | parse --regex '^\s*url\s+"(?<url>[^"]+)"'
  | get url
  | each {|url|
    let expanded = ($url | str replace --all '#{version}' $version)
    if ($expanded | str contains '#{') {
      error make { msg: $"url has an interpolation other than version: ($url)" }
    }
    $expanded
  }
}

# `text` with its `version` and its `sha256` lines replaced. `hashes` pair with
# the `sha256` lines in file order, which is also the order of the `url` lines.
export def render-release [text: string, version: string, hashes: list<string>]: nothing -> string {
  let sha_lines = ($text | lines | where {|l| $l =~ $sha_line })
  if ($sha_lines | length) != ($hashes | length) {
    error make { msg: $"expected ($hashes | length) sha256 lines to match the urls, found ($sha_lines | length)" }
  }

  mut next_hash = 0
  mut version_done = false
  mut out = []
  for line in ($text | lines) {
    if (not $version_done) and ($line =~ $version_line) {
      $version_done = true
      $out = ($out | append ($line | str replace --regex $version_line $"${1}${2}($version)${2}"))
    } else if $line =~ $sha_line {
      let h = ($hashes | get $next_hash)
      $next_hash += 1
      $out = ($out | append ($line | str replace --regex '[0-9a-f]{64}' $h))
    } else {
      $out = ($out | append $line)
    }
  }
  if not $version_done { error make { msg: "no version line found" } }
  restore-trailing-newline $text ($out | str join "\n")
}

# `text` with its `version` and `commit_hash` replaced, for a branch-tracked Package.
export def render-branch [text: string, version: string, commit: string]: nothing -> string {
  let version_re = ("(?m)" + $version_line)
  let commit_re = ("(?m)" + $commit_line)
  if not ($text =~ $commit_re) { error make { msg: "no commit_hash line found" } }
  if not ($text =~ $version_re) { error make { msg: "no version line found" } }
  $text
  | str replace --regex $version_re $"${1}${2}($version)${2}"
  | str replace --regex $commit_re $"${1}${2}($commit)${2}"
}

# The version a release tag stands for: the tag without a leading `v`.
export def version-from-tag [tag: string]: nothing -> string {
  $tag | str replace --regex '^v' ''
}

# SHA-256 of what `url` serves. Fails on any HTTP error or empty download.
export def download-sha256 [url: string, --max-time: duration = 10min]: nothing -> string {
  let dir = (mktemp --directory)
  let file = ($dir | path join "download")
  let seconds = ($max_time / 1sec | math ceil | into string)
  let r = (^curl --fail --location --silent --show-error --retry 3 --retry-max-time $seconds --connect-timeout 20 --max-time $seconds --output $file $url | complete)
  let size = (if ($file | path exists) { ls $file | get 0.size } else { 0b })
  if $r.exit_code != 0 or $size == 0b {
    rm --recursive --force $dir
    error make { msg: $"download failed: ($url) ($r.stderr | str trim)" }
  }
  let sha = (open --raw $file | hash sha256)
  rm --recursive --force $dir
  $sha
}

# The url -> sha256 closure to use: `fetch` when given (tests), else a real download.
def hasher [fetch: any]: nothing -> closure {
  if $fetch == null { {|url| download-sha256 $url } } else { $fetch }
}

# Where a Package's file lives in the tap, relative to its root.
export def package-file [pkg: record]: nothing -> string {
  $"(if $pkg.kind == "cask" { "Casks" } else { "Formula" })/($pkg.name).rb"
}

# Updates one Package's file in place from `latest`, the Upstream's newest state:
# `{version}` for a release-tracked Package, `{commit, date}` for a branch-tracked one.
# Never leaves the file half-updated: on any failure it is byte-identical to before.
export def update-package [
  pkg: record
  latest: record
  --root: path = "."
  --fetch-hash: closure # url -> sha256; defaults to download-sha256. Tests replace it.
]: nothing -> record {
  let rel = (package-file $pkg)
  let path = ($root | path join $rel)
  let original = (open --raw $path)
  let result = { name: $pkg.name, file: $rel, status: "current", from: "", to: "", message: "", commit_message: "" }

  # Work out the new text first; nothing is written until every download succeeded.
  let plan = (try {
    match $pkg.tracking {
      "release" => {
        let from = (find-in $original $version_line)
        let to = $latest.version
        require-match $to '^[0-9A-Za-z][0-9A-Za-z._+-]*$' "version"
        if $from == $to {
          { status: "current", from: $from, to: $to }
        } else {
          let hash = (hasher $fetch_hash)
          let hashes = (expand-urls $original $to | each {|url| do $hash $url })
          {
            status: "updated", from: $from, to: $to
            text: (render-release $original $to $hashes)
            commit_message: $"Update ($pkg.display) to version ($to)"
          }
        }
      }
      "branch" => {
        let from = (find-in $original $version_line)
        let current_commit = (find-in $original $commit_line)
        require-match $latest.commit '^[0-9a-f]{7,40}$' "commit"
        require-match $latest.date '^\d{4}-\d{2}-\d{2}$' "date"
        if ($latest.commit | str starts-with $current_commit) {
          { status: "current", from: $from, to: $from }
        } else {
          let short = ($latest.commit | str substring 0..<7)
          let to = $"($latest.date | str replace --all '-' '')-($short)"
          {
            status: "updated", from: $from, to: $to
            text: (render-branch $original $to $short)
            commit_message: $"Update ($pkg.display) to commit ($short)"
          }
        }
      }
      $other => { error make { msg: $"unknown tracking mode: ($other)" } }
    }
  } catch {|e|
    { status: "failed", message: $e.msg }
  })

  if $plan.status != "updated" { return ($result | merge $plan) }

  $plan.text | save --force --raw $path
  let check = (^ruby -c $path | complete)
  if $check.exit_code != 0 {
    $original | save --force --raw $path
    return ($result | merge { status: "failed", message: $"ruby -c rejected the updated file: ($check.stderr | str trim)" })
  }
  $result | merge ($plan | reject text)
}

# Commits an updated Package's file as its own commit and pushes it to `branch`,
# rebasing onto whatever landed there meanwhile and retrying a few times.
export def publish [
  result: record # an `update-package` result with status "updated"
  --root: path = "."
  --remote: string = "origin"
  --branch: string = "main"
  --retry-delay: duration = 2sec # attempt N waits N times this before trying again
] {
  # A manual dispatch can run from any branch; never push its commits to `branch`.
  let current = (^git -C $root rev-parse --abbrev-ref HEAD | str trim)
  if $current != $branch {
    error make { msg: $"refusing to publish from branch ($current): updates are only pushed from ($branch)" }
  }
  # A Package that fails to publish must leave nothing behind: a staged file or local
  # commit would ride along with the next Package's commit or push.
  let start = (^git -C $root rev-parse HEAD | str trim)
  try {
    git-in $root add $result.file
    git-in $root commit --quiet --message $result.commit_message
    push-with-retries $root $remote $branch $retry_delay $result.file
  } catch {|e|
    ^git -C $root rebase --abort | complete | ignore
    # Drop our commit and unstage, then restore only this Package's file: edits to
    # other files (a developer running this locally) are not ours to discard.
    ^git -C $root reset --quiet $start | complete | ignore
    ^git -C $root checkout -- $result.file | complete | ignore
    error make { msg: $e.msg }
  }
}

def push-with-retries [root: string, remote: string, branch: string, delay: duration, file: string] {
  mut last_error = ""
  for attempt in 1..3 {
    let pulled = (^git -C $root pull --quiet --rebase $remote $branch | complete)
    if $pulled.exit_code == 0 {
      let pushed = (^git -C $root push --quiet $remote $"HEAD:refs/heads/($branch)" | complete)
      if $pushed.exit_code == 0 { return }
      $last_error = $pushed.stderr
    } else {
      $last_error = $pulled.stderr
      ^git -C $root rebase --abort | complete | ignore
    }
    sleep ($attempt * $delay)
  }
  error make { msg: $"could not publish ($file) after 3 attempts: ($last_error | str trim)" }
}

# The Packages the tap publishes, each with its Upstream and Tracking mode.
export def load-manifest [path: path]: nothing -> list<record> {
  let packages = (open $path | get package)
  for p in $packages {
    for field in [name display kind upstream tracking] {
      if ($p | get --optional $field) == null {
        error make { msg: $"manifest: a package is missing `($field)`: ($p | to nuon)" }
      }
    }
    if $p.kind not-in [cask formula] {
      error make { msg: $"manifest: ($p.name): kind must be cask or formula, not ($p.kind)" }
    }
    if $p.tracking not-in [release branch] {
      error make { msg: $"manifest: ($p.name): tracking must be release or branch, not ($p.tracking)" }
    }
    if $p.tracking == "branch" and ($p | get --optional branch) == null {
      error make { msg: $"manifest: ($p.name): a branch-tracked package needs a `branch`" }
    }
  }
  $packages
}

# The Upstream's newest state for `pkg`: `{version}` or `{commit, date}`.
export def fetch-latest [pkg: record]: nothing -> record {
  let token = ($env | get --optional GITHUB_TOKEN)
  let headers = (
    [Accept application/vnd.github+json User-Agent tap-updater]
    | append (if $token != null { [Authorization $"Bearer ($token)"] } else { [] })
  )
  let api = $"https://api.github.com/repos/($pkg.upstream)"
  match $pkg.tracking {
    "release" => {
      let tag = (http get --max-time 60sec --headers $headers $"($api)/releases/latest" | get tag_name)
      { version: (version-from-tag $tag) }
    }
    "branch" => {
      let c = (http get --max-time 60sec --headers $headers $"($api)/commits/($pkg.branch)")
      { commit: $c.sha, date: ($c.commit.committer.date | str substring 0..<10) }
    }
  }
}

# Updates every Package in `manifest` (or just `--only`), publishing each as its own commit.
# One Package failing never stops the others; the result list says what happened to each.
export def update-all [
  manifest: list<record>
  --only: string
  --root: path = "."
  --latest: closure # pkg -> latest record; defaults to fetch-latest
  --fetch-hash: closure # url -> sha256; defaults to download-sha256
  --no-publish # leave the updated files uncommitted
]: nothing -> list<record> {
  let selected = (if $only == null { $manifest } else { $manifest | where name == $only })
  if ($selected | is-empty) {
    error make { msg: $"no package named ($only) in the manifest" }
  }

  $selected | each {|pkg|
    let result = (try {
      let state = (if $latest == null { fetch-latest $pkg } else { do $latest $pkg })
      update-package $pkg $state --root $root --fetch-hash (hasher $fetch_hash)
    } catch {|e|
      { name: $pkg.name, status: "failed", message: $e.msg, from: "", to: "", file: "", commit_message: "" }
    })

    if $result.status == "updated" and not $no_publish {
      try { publish $result --root $root; $result } catch {|e|
        $result | merge { status: "failed", message: $e.msg }
      }
    } else {
      $result
    }
  }
}

# Updates the tap's Packages. Exits 1 if any Package failed, after trying all of them.
def main [
  --only: string # update just this Package
  --manifest: path = "scripts/packages.toml"
  --no-publish # edit files but do not commit or push
] {
  if (not $no_publish) {
    ^git config --local user.email "action@github.com"
    ^git config --local user.name "GitHub Action"
  }
  let results = (update-all (load-manifest $manifest) --only $only --no-publish=$no_publish)

  let lines = ($results | each {|r|
    match $r.status {
      "updated" => $"✅ ($r.name): ($r.from) → ($r.to)"
      "current" => $"⏸️ ($r.name): up to date at ($r.from)"
      _ => $"❌ ($r.name): ($r.message)"
    }
  })
  print ($lines | str join "\n")
  let summary = ($env | get --optional GITHUB_STEP_SUMMARY)
  if $summary != null {
    $"### Package updates\n\n($lines | each {|l| '- ' + $l } | str join "\n")\n" | save --append $summary
  }
  if ($results | where status == "failed" | is-not-empty) { exit 1 }
}

def --wrapped git-in [root: string, ...args: string] {
  let r = (^git -C $root ...$args | complete)
  if $r.exit_code != 0 { error make { msg: $"git ($args | str join ' ') failed: ($r.stderr | str trim)" } }
  null
}

# Upstream values end up inside Ruby source and URLs: accept only the expected shape.
def require-match [value: string, pattern: string, what: string] {
  if not ($value =~ $pattern) {
    error make { msg: $"upstream ($what) is not in the expected form: ($value | to nuon)" }
  }
}

# The quoted value on the first line of `text` matching `pattern` (whose group 3 is the value).
def find-in [text: string, pattern: string]: nothing -> string {
  let found = ($text | lines | parse --regex $pattern)
  if ($found | is-empty) { error make { msg: $"no line matching ($pattern)" } }
  $found | first | get capture2
}

def restore-trailing-newline [original: string, rendered: string]: nothing -> string {
  if ($original | str ends-with "\n") { $rendered + "\n" } else { $rendered }
}
