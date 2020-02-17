## Vim

Larry Tesler was right about modes...

### Common command-mode actions to remember

- `ctrl-b` and `ctrl-f`: page up and page down
- `:w`: save (write) file
- `dd`: delete current line
- `u`: undo
- `ctrl-r`: redo
- `/foo` + `enter`: search for occurrences of 'foo'
- `n` and `N`: search forward and back
- `%s/foo/bar/gc` + `enter`: replace foo with bar.
    - `g` is *greedy*, keeps going after first occurrence in each line
    - `c` is *confirm*