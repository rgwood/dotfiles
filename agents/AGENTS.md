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