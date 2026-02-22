## Scripting Preferences

### Use Python over Bash
- For any script more than a few lines, prefer Python over Bash
- Python provides better error handling, readability, and maintainability
- Reserve Bash for simple one-liners or basic system operations

### Use UV with PEP 723 Dependencies
- Always use `uv` with PEP 723 inline dependencies for standalone Python scripts
- Include the shebang and dependency block at the top of each script:

```python
#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "requests",
#     "other-package>=1.0",
# ]
# ///
```

You can run the scripts like `uv run foo.py`, but make sure to `chmod +x` any scripts that a user might want to run later.

### Type Checking Python Scripts
- Always type check Python scripts before asking the user to run them
- Use `ty` (Astral's type checker) with `--with-requirements` to automatically pick up PEP 723 dependencies:

```bash
uvx --with-requirements=script.py ty check script.py
```

## Git Conventions

### Branch Naming
- Always prefix new branches with `reilly.wood/`, e.g. `reilly.wood/make-frobnicator-faster`

## Writing Style

When generating prose — PR descriptions, commit messages, documentation, blog drafts, comments — match this voice.

### Voice and Tone
- Casual, direct, and conversational — like explaining something to a colleague
- Use first person naturally ("I think", "I found", "IMO")
- Be honest about uncertainty and trade-offs ("I'm not sure", "this could be better", "I can't quite decide")
- No corporate speak, no filler, no false enthusiasm
- Humor is fine when it's natural, not forced — deadpan and self-deprecating over clever

Examples of the right tone:
- "Many corners were cut during the development of this project!"
- "Is it dumb? Yes. Does it solve this one person's very specific problem? Also yes!"
- "I initially thought 1) would be just a few lines, and then this PR blew up into much more extensive changes"

### Structure
- Lead with "why" before "what" — establish the problem or context first
- Keep paragraphs short (1-3 sentences typical)
- Use headers and lists to organize, but only when they serve the content
- Match detail level to complexity — one-liners for trivial things, thorough explanations for complex ones

### Technical Writing
- Assume technical literacy but explain jargon on first use
- Use concrete examples and code snippets over abstract explanations
- Backtick-wrap code identifiers, commands, and config keys
- Credit others' work and link to sources naturally
- Admit mistakes and learning moments — don't pretend to be authoritative

### PR Descriptions

**Opening:** Lead with the problem or context. No preamble, just straight into what's wrong or what motivated the change.

> "The SQLite code that I wrote a while back was slow. I profiled it, made some tweaks, and it's now about 2.5 times faster."

> "I have been staring at `nu::shell::external_command` errors a lot lately, and I think it's confusing that they are just titled 'External command'. Like, I look at this and think 'OK, what about an external command?'"

For straightforward bug fixes, open with a `Closes #NNNN`:

> "Closes #6987. `where` does the same thing as `find --predicate`, so let's remove the `--predicate` flag."

**Detail level matches complexity.** This is critical — don't over-explain simple things or under-explain complex ones.

- Trivial changes get one-liners: "Link was broken with a 404." / "Long overdue."
- Medium changes get a focused paragraph or bulleted list
- Major features get multi-section writeups with motivation, examples, measurements, and future work

**Headers** for complex PRs, drawn from this repertoire as needed:
- `# Description` / `# What?` / `## Summary`
- `# Why?` / `## Context` / `## Motivation`
- `## Deets` / `# Details`
- `## Before` / `## After` (with screenshots)
- `## Future Work`
- `## Build measurements`
- `# Testing` / `## Testing Performed`

**Technical explanations** are concrete and evidence-based. Explain *what you observed*, then *what you did*, then *the result*. Use profiling data, benchmarks, and measurements:

> "I downloaded `TPC-H-small.db` and ran `open TPC-H-small.db` with Superluminal attached. Most time was being spent in `convert_sqlite_row_to_nu_value`... that `let_column = c.to_string();` line is expensive and doing nothing (oops!). This PR speeds things up from 1,355ms to 533ms."

**Screenshots** go in Before/After pairs with `## Before` / `## After` headers.

**Bundled changes:** When opportunistic cleanup is included alongside other work, flag it: "While I was in the area I did a quick spelling+wording pass over the comments in the file." For multi-part changes, use numbered lists and mention that changes are in separate commits when applicable.

**PR-type patterns:**
- **Bug fixes:** Problem → root cause → fix → how it was tested
- **New features:** Motivation/use case → feature description with examples → dependency/build cost → future work
- **Cleanup/refactoring:** Acknowledge it's boring, explain the "why", keep it brief: "Another very boring PR cleaning up and documenting some of `explore`'s innards."
- **Dependency upgrades:** What changed, build/size measurements, whether there are functional changes
- **Proposals/breaking changes:** Present the change, explain trade-offs clearly, show before/after behaviour, invite discussion: "Please comment if you disagree with this proposal; nothing is set in stone."

**Recurring natural phrases:** "my bad", "while I was in the area", "IMO", "FWIW", "oops", "idk", "I think"/"I believe", and crediting others by name with `@` mentions.