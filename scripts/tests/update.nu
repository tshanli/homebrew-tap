use ../update.nu *

const fixtures = (path self | path dirname | path join "fixtures")

def fixture [name: string] { open --raw ($fixtures | path join $name) }

def test-expand-urls-substitutes-version-in-a-cask [] {
  let urls = (expand-urls (fixture "kazumi.rb") "9.9.9")
  assert equal $urls ["https://github.com/Predidit/Kazumi/releases/download/9.9.9/Kazumi_macos_9.9.9.dmg"]
}

def test-expand-urls-lists-every-platform-url-in-file-order [] {
  let urls = (expand-urls (fixture "upgit.rb") "1.2.3")
  assert equal $urls [
    "https://github.com/pluveto/upgit/releases/download/v1.2.3/upgit_macos_arm64.zip"
    "https://github.com/pluveto/upgit/releases/download/v1.2.3/upgit_macos_amd64.zip"
    "https://github.com/pluveto/upgit/releases/download/v1.2.3/upgit_linux_arm64.zip"
    "https://github.com/pluveto/upgit/releases/download/v1.2.3/upgit_linux_amd64.zip"
  ]
}

def test-expand-urls-rejects-interpolation-it-cannot-evaluate [] {
  let text = 'url "https://x.test/#{version}/a_#{Hardware::CPU.intel? ? "x64" : "arm"}.dmg"'
  let r = (try { expand-urls $text "1.0"; "no error" } catch {|e| $e.msg })
  assert str contains $r "interpolation"
}

def a-hash [c: string] { $c | fill --character $c --width 64 }

def test-render-release-sets-version-and-hash-in-a-cask [] {
  let out = (render-release (fixture "kazumi.rb") "9.9.9" [(a-hash "a")])
  assert str contains $out 'version "9.9.9"'
  assert str contains $out $'sha256 "(a-hash "a")"'
  assert (not ($out | str contains "2.4.4"))
  assert (not ($out | str contains "372ec688a8"))
}

def test-render-release-assigns-hashes-to-platform-urls-in-order [] {
  let hashes = (["1" "2" "3" "4"] | each {|c| a-hash $c })
  let out = (render-release (fixture "upgit.rb") "0.4.0" $hashes)
  let shas = ($out | lines | parse --regex 'sha256 "(?<sha>[0-9a-f]{64})"' | get sha)
  assert equal $shas $hashes
  assert str contains $out 'version "0.4.0"'
  assert equal ($out | lines | length) ((fixture "upgit.rb") | lines | length)
}

def test-render-release-rejects-a-hash-count-that-does-not-match-the-sha256-lines [] {
  let r = (try { render-release (fixture "upgit.rb") "0.4.0" ["a"]; "no error" } catch {|e| $e.msg })
  assert str contains $r "sha256"
}

def test-render-branch-sets-version-and-commit-hash [] {
  let out = (render-branch (fixture "sourcegit-develop.rb") "20261110-4f18ef1" "4f18ef1")
  assert str contains $out "version '20261110-4f18ef1'"
  assert str contains $out "commit_hash = '4f18ef1'"
  assert (not ($out | str contains "3e65576"))
}

def test-version-from-tag-drops-a-leading-v-only [] {
  assert equal (version-from-tag "v0.3.0") "0.3.0"
  assert equal (version-from-tag "2.4.4") "2.4.4"
  assert equal (version-from-tag "v1.0.0-vnext") "1.0.0-vnext"
}

def test-download-sha256-hashes-the-downloaded-body [] {
  let dir = (mktemp --directory)
  "hello\n" | save ($dir | path join "body.txt")
  let sha = (download-sha256 $"file://($dir)/body.txt")
  assert equal $sha "5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03"
}

def test-download-sha256-fails-when-the-url-does-not-resolve [] {
  let dir = (mktemp --directory)
  let r = (try { download-sha256 $"file://($dir)/missing.bin"; "no error" } catch {|e| $e.msg })
  assert str contains $r "download failed"
}

def test-download-sha256-fails-on-an-empty-download [] {
  let dir = (mktemp --directory)
  "" | save ($dir | path join "empty.bin")
  let r = (try { download-sha256 $"file://($dir)/empty.bin"; "no error" } catch {|e| $e.msg })
  assert str contains $r "download failed"
}

# The failure policy rests on this: an HTTP 404 must fail, not hash the error page.
def test-download-sha256-fails-on-an-http-404 [] {
  let dir = (mktemp --directory)
  "present\n" | save ($dir | path join "present.txt")
  let port = (random int 20000..40000)
  let pid = (^sh -c $"python3 -I -m http.server ($port) --bind 127.0.0.1 --directory ($dir) >/dev/null 2>&1 & echo $!" | str trim)
  sleep 1sec
  let found = (try { download-sha256 $"http://127.0.0.1:($port)/present.txt" } catch {|e| $"error: ($e.msg)" })
  let missing = (try { download-sha256 $"http://127.0.0.1:($port)/missing.zip"; "no error" } catch {|e| $e.msg })
  ^kill $pid
  assert equal $found "14bca160a84ec9e8e5b25cb86ec8b0945f870b8781c8e94ef883b58d27b508db"
  assert str contains $missing "download failed"
}

# A throwaway tap root holding one Package's file; returns the root.
def tap-root [kind: string, name: string]: nothing -> string {
  let root = (mktemp --directory)
  let dir = (if $kind == "cask" { "Casks" } else { "Formula" })
  mkdir ($root | path join $dir)
  fixture $"($name).rb" | save ($root | path join $dir $"($name).rb")
  $root
}

const kazumi = { name: "kazumi", display: "Kazumi", kind: "cask", upstream: "Predidit/Kazumi", tracking: "release" }
const sourcegit = { name: "sourcegit-develop", display: "SourceGit develop", kind: "formula", upstream: "sourcegit-scm/sourcegit", tracking: "branch", branch: "develop" }

def test-update-package-release-rewrites-version-and-hashes [] {
  let root = (tap-root "cask" "kazumi")
  let file = ($root | path join "Casks" "kazumi.rb")
  let seen = (mktemp --directory)
  let r = (update-package $kazumi { version: "9.9.9" } --root $root --fetch-hash {|url| $url | save --append ($seen | path join "urls"); a-hash "b" })
  assert equal $r.status "updated"
  assert equal $r.from "2.4.4"
  assert equal $r.to "9.9.9"
  assert equal $r.commit_message "Update Kazumi to version 9.9.9"
  assert equal $r.file "Casks/kazumi.rb"
  let text = (open --raw $file)
  assert str contains $text 'version "9.9.9"'
  assert str contains $text $'sha256 "(a-hash "b")"'
  # the url that was hashed is the one the file itself will use
  assert equal (open --raw ($seen | path join "urls")) "https://github.com/Predidit/Kazumi/releases/download/9.9.9/Kazumi_macos_9.9.9.dmg"
}

def test-update-package-release-is-current-when-versions_match [] {
  let root = (tap-root "cask" "kazumi")
  let before = (open --raw ($root | path join "Casks" "kazumi.rb"))
  let r = (update-package $kazumi { version: "2.4.4" } --root $root --fetch-hash {|url| error make { msg: "must not download" } })
  assert equal $r.status "current"
  assert equal (open --raw ($root | path join "Casks" "kazumi.rb")) $before
}

def test-update-package-release-leaves-the-file-alone-when-a-download-fails [] {
  let root = (tap-root "formula" "upgit")
  let file = ($root | path join "Formula" "upgit.rb")
  let before = (open --raw $file)
  let r = (update-package { name: "upgit", display: "Upgit", kind: "formula", upstream: "pluveto/upgit", tracking: "release" } { version: "0.4.0" } --root $root --fetch-hash {|url| if ($url | str contains "linux_arm64") { error make { msg: $"download failed: ($url)" } } else { a-hash "c" } })
  assert equal $r.status "failed"
  assert str contains $r.message "linux_arm64"
  assert equal (open --raw $file) $before
}

def test-update-package-release-restores-the-file-when-ruby-rejects-it [] {
  let root = (mktemp --directory)
  mkdir ($root | path join "Formula")
  let file = ($root | path join "Formula" "broken.rb")
  let before = $"class Broken < Formula\n  version \"1.0\"\n  url \"https://x.test/v#{version}.zip\"\n  sha256 \"(a-hash "0")\"\n"
  $before | save $file
  let r = (update-package { name: "broken", display: "Broken", kind: "formula", upstream: "x/broken", tracking: "release" } { version: "2.0" } --root $root --fetch-hash {|url| a-hash "d" })
  assert equal $r.status "failed"
  assert equal (open --raw $file) $before
}

def test-update-package-branch-moves-to-the-new-commit [] {
  let root = (tap-root "formula" "sourcegit-develop")
  let r = (update-package $sourcegit { commit: "4f18ef1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", date: "2026-11-10" } --root $root --fetch-hash {|url| error make { msg: "must not download" } })
  assert equal $r.status "updated"
  assert equal $r.commit_message "Update SourceGit develop to commit 4f18ef1"
  assert equal $r.to "20261110-4f18ef1"
  let text = (open --raw ($root | path join "Formula" "sourcegit-develop.rb"))
  assert str contains $text "version '20261110-4f18ef1'"
  assert str contains $text "commit_hash = '4f18ef1'"
}

def test-update-package-branch-is-current-when-the-commit-matches [] {
  let root = (tap-root "formula" "sourcegit-develop")
  let r = (update-package $sourcegit { commit: "3e65576bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", date: "2026-11-09" } --root $root)
  assert equal $r.status "current"
}

def --wrapped sh-git [dir: string, ...args: string]: nothing -> string {
  let r = (^git -C $dir -c user.name=Test -c user.email=test@example.com ...$args | complete)
  if $r.exit_code != 0 { error make { msg: $"git ($args | str join ' ') failed: ($r.stderr)" } }
  $r.stdout | str trim
}

# A bare remote with `main` seeded from the three fixtures, plus a clone of it.
def tap-with-remote []: nothing -> record<remote: string, clone: string> {
  let base = (mktemp --directory)
  let remote = ($base | path join "remote.git")
  let seed = ($base | path join "seed")
  ^git init --quiet --bare --initial-branch=main $remote
  ^git clone --quiet $remote $seed
  mkdir ($seed | path join "Casks") ($seed | path join "Formula")
  fixture "kazumi.rb" | save ($seed | path join "Casks" "kazumi.rb")
  fixture "upgit.rb" | save ($seed | path join "Formula" "upgit.rb")
  sh-git $seed add .
  sh-git $seed commit --quiet --message "seed"
  sh-git $seed push --quiet origin HEAD:main
  let clone = ($base | path join "clone")
  ^git clone --quiet $remote $clone
  sh-git $clone config user.name Test
  sh-git $clone config user.email test@example.com
  { remote: $remote, clone: $clone }
}

def test-publish-commits-each-package-separately-on-the-remote [] {
  let t = (tap-with-remote)
  "# a\n" | save --append ($t.clone | path join "Casks" "kazumi.rb")
  publish { file: "Casks/kazumi.rb", commit_message: "Update Kazumi to version 9.9.9" } --root $t.clone
  "# b\n" | save --append ($t.clone | path join "Formula" "upgit.rb")
  publish { file: "Formula/upgit.rb", commit_message: "Update Upgit to version 0.4.0" } --root $t.clone
  let log = (sh-git $t.remote log --format=%s main | lines)
  assert equal $log ["Update Upgit to version 0.4.0" "Update Kazumi to version 9.9.9" "seed"]
  assert equal (sh-git $t.remote show --stat --format= main~1 | lines | length) 2
}

def test-publish-rebases-onto-a-remote-that-moved-meanwhile [] {
  let t = (tap-with-remote)
  # someone else pushes to main after our clone was taken
  let other = ($t.clone + "-other")
  ^git clone --quiet $t.remote $other
  "unrelated\n" | save ($other | path join "NOTES.md")
  sh-git $other add .
  sh-git $other commit --quiet --message "someone else"
  sh-git $other push --quiet origin HEAD:main

  "# a\n" | save --append ($t.clone | path join "Casks" "kazumi.rb")
  publish { file: "Casks/kazumi.rb", commit_message: "Update Kazumi to version 9.9.9" } --root $t.clone
  let log = (sh-git $t.remote log --format=%s main | lines)
  assert equal $log ["Update Kazumi to version 9.9.9" "someone else" "seed"]
}

const upgit = { name: "upgit", display: "Upgit", kind: "formula", upstream: "pluveto/upgit", tracking: "release" }

def test-update-all-publishes-the-packages-that-succeed-and-reports-the-one-that-fails [] {
  let t = (tap-with-remote)
  let latest = {|pkg| { version: "9.9.9" } }
  let fetch = {|url| if ($url | str contains "upgit") { error make { msg: $"download failed: ($url) 404" } } else { a-hash "e" } }
  let results = (update-all [$kazumi $upgit] --root $t.clone --latest $latest --fetch-hash $fetch)

  assert equal ($results | select name status) [{ name: "kazumi", status: "updated" } { name: "upgit", status: "failed" }]
  assert str contains ($results | where name == "upgit" | first | get message) "404"
  # kazumi is on the remote as its own commit; upgit stays on its last good version
  assert equal (sh-git $t.remote log --format=%s main | lines) ["Update Kazumi to version 9.9.9" "seed"]
  assert str contains (sh-git $t.remote show main:Formula/upgit.rb) 'version "0.3.0"'
  assert equal (sh-git $t.clone status --porcelain) ""
}

def test-update-all-reports-a-package_whose_upstream_lookup_fails [] {
  let t = (tap-with-remote)
  let latest = {|pkg| error make { msg: "api down" } }
  let results = (update-all [$kazumi] --root $t.clone --latest $latest)
  assert equal ($results | get status) ["failed"]
  assert str contains ($results | first | get message) "api down"
}

def test-update-all-only-touches-the-named-package [] {
  let t = (tap-with-remote)
  let latest = {|pkg| { version: "9.9.9" } }
  let results = (update-all [$kazumi $upgit] --only "kazumi" --root $t.clone --latest $latest --fetch-hash {|url| a-hash "e" })
  assert equal ($results | get name) ["kazumi"]
}

def test-update-all-rejects-an-unknown-package-name [] {
  let t = (tap-with-remote)
  let r = (try { update-all [$kazumi] --only "nope" --root $t.clone --latest {|pkg| { version: "1" } }; "no error" } catch {|e| $e.msg })
  assert str contains $r "nope"
}

def test-load-manifest-rejects-a-branch-package-without-a-branch [] {
  let file = (mktemp --tmpdir --suffix .toml)
  '[[package]]
name = "x"
display = "X"
kind = "formula"
upstream = "a/b"
tracking = "branch"
' | save --force $file
  let r = (try { load-manifest $file; "no error" } catch {|e| $e.msg })
  assert str contains $r "branch"
}

def test-load-manifest-rejects-an-unknown-tracking-mode [] {
  let file = (mktemp --tmpdir --suffix .toml)
  '[[package]]
name = "x"
display = "X"
kind = "formula"
upstream = "a/b"
tracking = "nightly"
' | save --force $file
  let r = (try { load-manifest $file; "no error" } catch {|e| $e.msg })
  assert str contains $r "tracking"
}

# The manifest and the tap must list the same Packages: a file with no manifest entry
# is never updated, and an entry with no file can never succeed.
def test-the-manifest-lists_exactly_the_packages_in_the_tap [] {
  let repo = ($fixtures | path dirname | path dirname | path dirname)
  let manifest = (load-manifest ($repo | path join "scripts" "packages.toml"))
  let declared = ($manifest | each {|p| $"(if $p.kind == "cask" { "Casks" } else { "Formula" })/($p.name).rb" } | sort)
  let on_disk = (glob ($repo | path join "{Casks,Formula}" "*.rb") | each {|f| $f | path relative-to $repo } | sort)
  assert equal $declared $on_disk
}

def test-render-release-preserves-the-presence-of-a-final-newline [] {
  let h = (a-hash "f")
  let with_nl = (render-release $"version \"1\"\nsha256 \"(a-hash "0")\"\n" "2" [$h])
  let without_nl = (render-release $"version \"1\"\nsha256 \"(a-hash "0")\"" "2" [$h])
  assert ($with_nl | str ends-with "\n")
  assert (not ($without_nl | str ends-with "\n"))
}

def test-render-release-fails-when-there-is-no-version-line [] {
  let r = (try { render-release $"sha256 \"(a-hash "0")\"\n" "2" [(a-hash "f")]; "no error" } catch {|e| $e.msg })
  assert str contains $r "version"
}

def test-render-branch-fails-when-there-is-no-commit-hash-line [] {
  let r = (try { render-branch "version '1'\n" "2" "abc1234"; "no error" } catch {|e| $e.msg })
  assert str contains $r "commit_hash"
}

def test-download-sha256-leaves-no-temporary-files-behind [] {
  let tmp = (mktemp --directory)
  let body = (mktemp --directory)
  "x\n" | save ($body | path join "x.txt")
  let module = ($fixtures | path dirname | path dirname | path join "update.nu")
  let r = (with-env { TMPDIR: $tmp } {
    ^nu --no-config-file -c $"use '($module)' *; download-sha256 'file://($body)/x.txt'" | complete
  })
  assert equal $r.exit_code 0
  assert equal (ls $tmp | length) 0
}

def test-load-manifest-rejects-an-unknown-kind [] {
  let file = (mktemp --tmpdir --suffix .toml)
  '[[package]]
name = "x"
display = "X"
kind = "app"
upstream = "a/b"
tracking = "release"
' | save --force $file
  let r = (try { load-manifest $file; "no error" } catch {|e| $e.msg })
  assert str contains $r "kind"
}

def test-update-all-reports-a-package-whose-commit-or-push-fails [] {
  let t = (tap-with-remote)
  "#!/bin/sh\nexit 1\n" | save ($t.clone | path join ".git" "hooks" "pre-commit")
  chmod +x ($t.clone | path join ".git" "hooks" "pre-commit")
  let results = (update-all [$kazumi] --root $t.clone --latest {|pkg| { version: "9.9.9" } } --fetch-hash {|url| a-hash "e" })
  assert equal ($results | get status) ["failed"]
  assert equal (sh-git $t.remote log --format=%s main | lines) ["seed"]
}

def test-publish-refuses-to-push-a-checkout-that-is-not-on-the-target-branch [] {
  let t = (tap-with-remote)
  sh-git $t.clone checkout --quiet -b feature
  "# a\n" | save --append ($t.clone | path join "Casks" "kazumi.rb")
  let r = (try { publish { file: "Casks/kazumi.rb", commit_message: "Update Kazumi to version 9.9.9" } --root $t.clone; "no error" } catch {|e| $e.msg })
  assert str contains $r "main"
  assert equal (sh-git $t.remote log --format=%s main | lines) ["seed"]
}

def test-update-package-rejects-a-release-version-that-is-not-a-plain-version [] {
  for bad in ['1.0${1}' '' ' ' "1.0\n2" 'a"b' '#{version}'] {
    let root = (tap-root "cask" "kazumi")
    let file = ($root | path join "Casks" "kazumi.rb")
    let before = (open --raw $file)
    let r = (update-package $kazumi { version: $bad } --root $root --fetch-hash {|url| a-hash "b" })
    assert equal $r.status "failed" $"version ($bad | to nuon) should be rejected"
    assert str contains $r.message "version"
    assert equal (open --raw $file) $before
  }
}

def test-update-package-rejects-a-branch-commit-or-date-that-is-malformed [] {
  for bad in [{ commit: "", date: "2026-11-10" } { commit: "zzzzzzzz", date: "2026-11-10" } { commit: "4f18ef1aaaa", date: "" } { commit: "4f18ef1aaaa", date: "yesterday" }] {
    let root = (tap-root "formula" "sourcegit-develop")
    let file = ($root | path join "Formula" "sourcegit-develop.rb")
    let before = (open --raw $file)
    let r = (update-package $sourcegit $bad --root $root)
    assert equal $r.status "failed" $"($bad | to nuon) should be rejected"
    assert equal (open --raw $file) $before
  }
}

def test-render-release-keeps-single-quoted-version [] {
  let text = $"version '1.0'\nsha256 \"(a-hash "0")\"\n"
  let out = (render-release $text "2.0" [(a-hash "f")])
  assert str contains $out "version '2.0'"
}
