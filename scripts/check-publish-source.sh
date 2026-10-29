#!/bin/sh
set -eu

if ! git fetch --no-tags origin HEAD >/dev/null 2>&1; then
    printf '%s\n' 'Cannot read the current source branch from origin.' >&2
    exit 1
fi
if ! git merge-base --is-ancestor FETCH_HEAD HEAD; then
    printf '%s\n' 'Cannot publish: source is behind the current default branch.' >&2
    exit 1
fi

if ! git diff --quiet -- . ':(exclude)keeper/static/**' ':(exclude)usage/static/**' ||
   ! git diff --cached --quiet -- . ':(exclude)keeper/static/**' ':(exclude)usage/static/**'; then
    printf '%s\n' 'Cannot publish with changed tracked files. Commit or restore them first.' >&2
    exit 1
fi
