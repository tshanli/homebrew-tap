# Homebrew Tap

A personal Homebrew tap that publishes third-party software and keeps it current with upstream releases.

## 📦 Available Packages

Formulas:

- **sourcegit-develop** - SourceGit (GUI Git client) development builds, tracking the `develop` branch
- **upgit** - Upload tool for various cloud storage services

Casks:

- **kazumi** - Anime streaming application

## 🤖 Automated Updates

One workflow, `.github/workflows/update.yml`, updates every package:

- **Daily**: runs at 1 AM UTC.
- **Manual**: run it from the Actions tab; give a package name to update just that one, or leave it blank for all.
- **Commits**: each updated package is pushed straight to `main` as its own commit.
- **Failures**: if a release asset is not downloadable (for example, not uploaded yet), the run fails, that package is left on its last good version, and the next daily run tries again. Other packages still update.

The work is done by `scripts/update.nu` (Nushell). `scripts/packages.toml` lists each package, its upstream repository and whether it follows releases or a branch. For release-tracked packages the download URLs and checksums come from the package file's own `url` lines, so the script and the file cannot disagree.

To add a package, add its `.rb` file under `Formula/` or `Casks/` and an entry in `scripts/packages.toml`; a test fails if the two lists differ.

## 🧪 Local Testing

```bash
# Unit tests for the update script (needs nu, ruby, git, curl, python3)
nu scripts/test.nu

# Unit tests, then a dry run of the workflow with act (needs Docker)
brew install act
nu test-workflows.nu
```

## 📋 Usage

```bash
# Add this tap (the repository is tshanli/homebrew-tap)
brew tap tshanli/tap

# Install formulas
brew install tshanli/tap/sourcegit-develop
brew install tshanli/tap/upgit

# Install casks
brew install --cask tshanli/tap/kazumi
```
