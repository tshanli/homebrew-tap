# Homebrew Tap

A personal Homebrew tap that publishes third-party software as Homebrew recipes and keeps them current with upstream releases.

## Language

**Package**:
A **Formula** or a **Cask** published by this tap. The umbrella term for either kind.
_Avoid_: Formulae or formulas as an umbrella for both kinds

**Formula**:
A **Package** that installs a command-line tool or a build from source, defined in `Formula/`.

**Cask**:
A **Package** that installs a macOS application bundle, defined in `Casks/`.
_Avoid_: App

**Upstream**:
The external project whose software a **Package** redistributes.
_Avoid_: Source repo, vendor

**Tracking**:
How a **Package** follows its **Upstream**: either **release-tracked** or **branch-tracked**.

**Release-tracked**:
A **Package** that follows its **Upstream**'s latest tagged release.

**Branch-tracked**:
A **Package** that follows the head commit of one of its **Upstream**'s branches rather than a tagged release.
_Avoid_: Develop build, nightly

**Update**:
Moving a **Package** to its **Upstream**'s latest state and publishing the result to the tap.
_Avoid_: Bump, sync, refresh

## Relationships

- A **Package** is exactly one of a **Formula** or a **Cask**
- A **Package** has exactly one **Upstream** and exactly one **Tracking** mode
- An **Update** applies to exactly one **Package**
