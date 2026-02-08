---
name: pr-description
description: Generate a PR description matching Reilly's style. Use when asked to write or draft a PR description, or when creating a PR.
---

Generate a PR description that matches the voice and conventions below. Read the diff/commits carefully before writing.

## Title

- Short (3-8 words), imperative mood, verb-first
- Backtick-wrap code identifiers (commands, flags, config keys)
- No conventional commit prefixes (`feat:`, `fix:`, etc.)

Good titles:
- ``Support ctrl-c cancellation in `from csv`/`from tsv` ``
- `Diagnose missing logs better`
- `` Overhaul `explore` config ``
- `` `explore`: adopt `anyhow`, support `CustomValue`, remove help system ``
- `Set up build/test/fmt/clippy in CI`

## Description

No rigid template. Scale detail to match the change size.

### Trivial changes (deps, typos, CI tweaks)

One sentence or just an issue link. Don't over-explain:

> Closes #13064.

or:

> Long overdue.

### Medium changes

A paragraph of context (the problem / previous state), then what changed:

> Previously if we couldn't load any logs for a service, we would always show:
>
> > No logs found/available. Maybe try relaunching with `sudo systemctl-tui`
>
> Kind of crappy UX when more often than not, it's not a permission issue. This PR addresses that by attempting to diagnose the reason for missing logs before showing an error.

### Large/complex changes

Lead with motivation, then use a numbered list for the specifics. Acknowledge trade-offs and future work:

> Configuration in `explore` has always been confusing to me. This PR overhauls (and simplifies, I think) how configuration is done.
>
> ## Details
>
> 1. Configuration is now strongly typed. In `Explore::run()` we create an `ExploreConfig` struct from the more general Nu configuration... IMO this is a lot easier to reason about and trace than the previous approach.
> 2. We now inherit more configuration from the config used for regular Nu tables
> 3. The optional `selected_row` and `selected_column` configuration has been removed. I could re-add this if people really like the feature but I'm guessing nobody uses it.

## Tone

- Conversational and opinionated: "I think", "IMO", "kind of crappy"
- Honest about concerns: "I'm slightly concerned about the UX", "this needs more testing"
- Acknowledge scope creep or messiness when it happens
- Use emoji sparingly — only when it genuinely adds something

## Contributing to external repos

Start with a brief, genuine compliment. Explain the problem you encountered and how you fixed it:

> Hi, thanks for making `genai`; it's a really useful library!

Then explain the mechanism clearly with numbered steps or code.

## Other conventions

- Link issues with "Closes #N" or "Fixes #N" when applicable
- Include before/after screenshots for visual changes
- Paste error output for bug fixes
- Note future work and known limitations honestly
