# Homebrew Tap

This repository contains custom Homebrew formulae with automated updates.

## 📦 Available Formulas

- **sourcegit-develop** - SourceGit (GUI Git client) development builds
- **upgit** - Upload tool for various cloud storage services

## 🤖 Automated Updates

The repository includes GitHub Actions workflows that automatically check for and update formulas:

- **Daily Updates**: All formulas are checked daily at 2 AM UTC
- **Manual Triggers**: Workflows can be triggered manually from the Actions tab
- **Individual Updates**: Each formula has its own update workflow
- **Batch Updates**: The main workflow orchestrates all updates

### Workflows

1. `.github/workflows/update-sourcegit-develop.yml` - Updates SourceGit develop formula
2. `.github/workflows/update-upgit.yml` - Updates Upgit formula
3. `.github/workflows/update-formulas.yml` - Orchestrates all formula updates

## 🧪 Local Testing

Test workflows locally using [act](https://github.com/nektos/act):

```bash
# Install act
brew install act

# Quick syntax test
./test-workflows.sh
```

## 📋 Usage

```bash
# Add this tap
brew tap jiang2ji/homebrew-tap

# Install formulas
brew install sourcegit-develop
brew install upgit
```
