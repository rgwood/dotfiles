# General *nix stuff

## Symlinks

make a symlink with `ln -s /path/to/original /path/to/new`

Symlinks are just aliases - they stop working if original file is deleted. Hard links keep working.

## Grep

Use regular expressions with -e: `grep -e 'java.*openjdk'`

## Show filesizes in human units

`ls -lh`

## List processes that have a file open

`fuser file_name`