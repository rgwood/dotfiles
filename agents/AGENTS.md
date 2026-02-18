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