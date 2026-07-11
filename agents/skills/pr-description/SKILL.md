---
name: pr-description
description: Write PR descriptions in Reilly's voice using GOV.UK clarity principles — plain English, active voice, front-loaded content, and concrete evidence. Use when writing or drafting a PR description, or when creating a PR.
user-invokable: true
args:
  - name: target
    description: The diff, branch, or PR to describe (optional)
    required: false
---

Write PR descriptions that a non-specialist and an expert both grasp on first read — without losing any substance, nuance or precision. Open the writing up, do not dumb it down. This skill merges GOV.UK content design principles with Reilly's personal voice and PR conventions.

Read the diff and commits carefully before writing.

## Title

- Short (3 to 8 words), imperative mood, verb-first
- Backtick-wrap code identifiers (commands, flags, config keys)
- No conventional commit prefixes (`feat:`, `fix:`, etc.)
- Sentence case — capitalise only proper nouns

Good titles:
- ``Support ctrl-c cancellation in `from csv`/`from tsv` ``
- `Diagnose missing logs better`
- ``Overhaul `explore` config``
- `Set up build/test/fmt/clippy in CI`

## Voice and tone

- Casual, direct, conversational — like explaining something to a colleague
- First person ("I think", "I found", "IMO"). PR descriptions are personal contributions, not institutional documents — use "I", not "we" (unless referring to a team decision)
- Be honest about uncertainty and trade-offs ("I'm not sure", "this could be better", "I can't quite decide")
- No corporate speak, no filler, no false enthusiasm
- Humor is fine when it's natural — deadpan and self-deprecating over clever
- Acknowledge scope creep or messiness when it happens: "I initially thought 1) would be just a few lines, and then this PR blew up into much more extensive changes"
- Recurring natural phrases: "my bad", "while I was in the area", "IMO", "FWIW", "oops", "idk", "I think", "I believe"
- Use emoji sparingly — only when it genuinely adds something

## Plain English

- Use the active voice. Say who does what. Write "I reviewed the data", not "The data was reviewed"
- Keep sentences short — about 15 to 20 words, never more than about 25
- Keep paragraphs short — 1 to 3 sentences typical
- One idea per sentence, one topic per paragraph. If a sentence has more than one idea, split it
- Use everyday words. Replace jargon with plain alternatives:
  - use, not utilise or leverage
  - help, not facilitate or empower
  - work with, not collaborate, liaise or engage with
  - make or provide, not deliver
  - about, not in relation to or with regard to
  - so, not in order to
  - start, not commence; end, not terminate; buy, not purchase; enough, not sufficient
  - solve, fix or deal with, not tackle or combat
  - effect on, not impact on (do not use impact as a verb)
- Avoid metaphors and clichés: drive, unlock, deep dive, robust, key, ring-fence, hub, portal, landscape, ecosystem, going forward
- Avoid Latin abbreviations. Write "for example" not "eg", "that is" not "ie", "and so on" or "such as" not "etc". They confuse screen readers and some readers. Internet abbreviations like "IMO", "FWIW", "idk" are fine — they are informal, not jargon
- Contractions are fine for a warmer tone (I'll, we'll, don't), but write "cannot", not "can't". Avoid "should've", "could've", "would've"

## Structure

Front-load everything. Put the most important point first — in the description, each section, each paragraph and each sentence. Use the inverted pyramid: conclusion first, then detail, then background.

Lead with the "why" before the "what" — establish the problem or context first, then explain the change:

> The SQLite code that I wrote a while back was slow. I profiled it, made some tweaks, and it's now about 2.5 times faster.

> I have been staring at `nu::shell::external_command` errors a lot lately, and I think it's confusing that they are just titled 'External command'. Like, I look at this and think 'OK, what about an external command?'

For straightforward bug fixes, open with a `Closes #NNNN`:

> Closes #6987. `where` does the same thing as `find --predicate`, so let's remove the `--predicate` flag.

## Detail level

Scale detail to match the change size. Do not over-explain simple things or under-explain complex ones.

### Trivial changes (deps, typos, CI tweaks)

One sentence or an issue link:

> Closes #13064.

or:

> Long overdue.

### Medium changes

A paragraph of context (the problem or previous state), then what changed:

> Previously if we couldn't load any logs for a service, we would always show:
>
> > No logs found/available. Maybe try relaunching with `sudo systemctl-tui`
>
> Kind of crappy UX when more often than not, it's not a permission issue. This PR addresses that by attempting to diagnose the reason for missing logs before showing an error.

### Large or complex changes

Lead with motivation, then use a numbered list for the specifics. Acknowledge trade-offs and future work:

> Configuration in `explore` has always been confusing to me. This PR overhauls (and simplifies, I think) how configuration is done.
>
> ## Details
>
> 1. Configuration is now strongly typed. In `Explore::run()` we create an `ExploreConfig` struct from the more general Nu configuration... IMO this is a lot easier to reason about and trace than the previous approach.
> 2. We now inherit more configuration from the config used for regular Nu tables
> 3. The optional `selected_row` and `selected_column` configuration has been removed. I could re-add this if people really like the feature but I'm guessing nobody uses it.

## Headers

Use headers for complex PRs only — when they serve the content. Sentence case, no full stop, no dash, no question mark. Keep them under about 65 characters. Draw from this repertoire as needed:

- `# Description` / `# What` / `## Summary`
- `# Why` / `## Context` / `## Motivation`
- `## Deets` / `# Details`
- `## Before` / `## After` (with screenshots)
- `## Future work`
- `## Build measurements`
- `# Testing` / `## Testing performed`

## Lists

Introduce a bulleted list with a lead-in line that ends in a colon. Start each bullet lowercase. Keep each to one idea. No "and" or "or" after each item, no semicolons, no full stop after the last bullet (unless a bullet is itself a full sentence).

Use a numbered list only for a sequence the reader follows in order, or for ordered items in a change log. Numbered items are full sentences and end with a full stop.

## PR-type patterns

- **Bug fixes:** Problem, then root cause, then fix, then how it was tested. Paste error output.
- **New features:** Motivation and use case, then feature description with examples, then dependency or build cost, then future work
- **Cleanup or refactoring:** Acknowledge it's boring, explain the "why", keep it brief: "Another very boring PR cleaning up and documenting some of `explore`'s innards."
- **Dependency upgrades:** What changed, build and size measurements, whether there are functional changes
- **Proposals or breaking changes:** Present the change, explain trade-offs clearly, show before and after behaviour, invite discussion: "Please comment if you disagree with this proposal; nothing is set in stone."

## Technical writing

- Assume technical literacy but explain jargon on first use
- Use concrete examples and code snippets over abstract explanations
- Backtick-wrap code identifiers, commands and config keys
- Explain what you observed, then what you did, then the result. Use profiling data, benchmarks and measurements:

> I downloaded `TPC-H-small.db` and ran `open TPC-H-small.db` with Superluminal attached. Most time was being spent in `convert_sqlite_row_to_nu_value`... that `let column = c.to_string();` line is expensive and doing nothing (oops!). This PR speeds things up from 1,355ms to 533ms.

- Credit others' work and link to sources naturally. Use `@` mentions to credit contributors by name.

## Formatting

- Do not use bold or italics for emphasis. Plain words and good structure carry the meaning. Bold is acceptable only to name a literal interface element in an instruction (for example: select Save)
- Do not use exclamation marks, except sparingly for natural deadpan humor: "Is it dumb? Yes. Does it solve this one person's very specific problem? Also yes!"
- Do not use ALL CAPS for emphasis
- Numbers: write "one" but use numerals from 2 upwards (2, 9, 25). Use the % symbol with numerals (50%)
- Dates: write "4 June 2026" (no comma, no "th"). Use "to" for ranges ("4 to 8 June")

## Screenshots

Go in Before and After pairs with `## Before` / `## After` headers.

## Bundled changes

When opportunistic cleanup is included alongside other work, flag it: "While I was in the area I did a quick spelling and wording pass over the comments in the file." For multi-part changes, use numbered lists and mention that changes are in separate commits when applicable.

## Contributing to external repos

Start with a brief, genuine compliment. Explain the problem you encountered and how you fixed it:

> Hi, thanks for making `genai`; it's a really useful library!

Then explain the mechanism clearly with numbered steps or code.

## Other conventions

- Link issues with "Closes #N" or "Fixes #N" when applicable
- Note future work and known limitations honestly

## Before you finish: self-check

- Is the single most important thing first?
- Could a non-expert understand every sentence on first read?
- Is every sentence active, short and one idea?
- Is the detail level right for the change size — not over-explained, not under-explained?
- Have you removed all bold and italic emphasis, jargon, Latin abbreviations and marketing language?
- Is everything in sentence case, with descriptive headings?
- Could you cut any more words without losing meaning? If yes, cut them.
