## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues for `tshanli/homebrew-tap` via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `bug`, `enhancement`, `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one root `GLOSSARY.md`, ADRs in `docs/adr/`. See `docs/agents/domain.md`.

### External peers

Mode `claude`: `code-review` and `jury` call the Claude CLI (default model, effort `high`). See `docs/agents/cross-model.json`.
