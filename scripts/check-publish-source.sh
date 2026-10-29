#!/bin/sh
set -eu

if ! git diff --quiet -- . ':(exclude)keeper/static/**' ':(exclude)usage/static/**' ||
   ! git diff --cached --quiet -- . ':(exclude)keeper/static/**' ':(exclude)usage/static/**'; then
    printf '%s\n' 'Cannot publish with changed tracked files. Commit or restore them first.' >&2
    exit 1
fi

source_ref=$(git symbolic-ref --quiet refs/remotes/origin/HEAD) || {
    printf '%s\n' 'Cannot find the default source branch for origin.' >&2
    exit 1
}
source_branch=${source_ref#refs/remotes/origin/}
if ! git fetch --no-tags origin "refs/heads/$source_branch" >/dev/null 2>&1; then
    printf '%s\n' 'Cannot read the current source branch from origin.' >&2
    exit 1
fi
if ! git merge-base --is-ancestor FETCH_HEAD HEAD; then
    printf '%s\n' 'Cannot publish: source is behind the current default branch.' >&2
    exit 1
fi
