---
name: create-release-note
description: >-
  Write user-facing release notes by comparing two git commits. Use when the
  user asks for a release note, changelog, or what changed between versions
  or commits for this library.
---

# Create Release Note

## Required inputs

Always ask for **two commits** to compare (base and head) before writing.

- Accept SHAs, tags, branch tips, or commit message tips (e.g. `nitD`, `main`, `HEAD`)
- If either is missing, ask — do not guess or default
- Resolve both with `git rev-parse` / `git log` so the range is explicit

Compare with `git log <base>..<head>` and `git diff <base>..<head>`.

## What to include

The release note should only care about public facing api changes, bug fixes or ways that users interact with the release of this library.

Examples that belong:
- New/changed/removed public procs, types, flags, or CLI behavior
- Bug fixes that affect consumers (wrong output, crashes, failed builds/installs)
- Publish/install/copy behavior that changes what ships in a release artifact
- Documented usage changes consumers must know about

## What to ignore

If there are things like renaming files, moving tests around, more tests, etc. Do not care.

Also ignore:
- Internal refactors with no API or behavior change
- Comment-only / AGENT.md / OLS / gitignore churn
- CI/workflow edits unless they change how users obtain or use a release

## Workflow

1. Confirm base and head commits (ask if not given)
2. Collect commits + diff for that range only
3. Filter ruthlessly to include/ignore rules above
4. Write `RELEASE_NOTES.md` at the repo root (overwrite unless the user names another path)
5. If nothing user-facing changed, say so briefly — do not pad with internal work

## Output format

Match the first-release listing style: bold lead-ins with em dashes for capabilities/fixes, and markdown tables for public types and procedures. For a delta between two commits, only list what changed for consumers; omit empty sections. Do not dump the full stable API or a full Install guide unless those steps actually changed.

### Feature / fix bullets

```markdown
- **Build profiles** — name targets with entry path, flags, output dir, arch/OS, and mode (executable, etc.)
- **Custom CLI** — register commands (`run`, `build`, …) and pick a profile at the command line
- **Dependencies** — install shared libraries and other files into the output directory
- **Pre/post build steps** — hook scripts and actions around `odin run` / `odin build`
- **CLI flags** — parse `-key:value` arguments for project-specific options
```

### Public API tables

Group by area. Types first, then procedure tables:

```markdown
## Public API

### Types

| Name | Description |
|------|-------------|
| `Command` | Callback signature `(ctx: Context, p: Profile)` for registered CLI commands and build hooks. |
| `Context` | Holds profiles, commands, pre/post build steps, dependencies, and the default profile name. |
| `Profile` | Build target settings: `flags`, `name`, `output`, `entry`, `mode`, `os`, `arch`. |
| `Builtin_Command` | Built-in exec modes: `.Build`, `.Run`, `.Test`. |
| `RBS_Error` | Package-specific errors (script failure, missing command/profile, invalid test flags, etc.). |
| `Error` | Shared error union: `os.Error`, `RBS_Error`, or `Allocator_Error`. |

### Context & profiles

| Procedure | Description |
|-----------|-------------|
| `init_context` | Create an empty build context with allocated maps and lists. |
| `dispose_context` | Free all allocations owned by a context. |
| `add_profile` | Register a named profile; the first one becomes the default. |
| `get_profile` | Look up a profile by name; returns `(Profile, ok)`. |
| `add_command` | Register a CLI command name to a `Command` callback. |
| `add_pre_build_step` | Append a hook that runs before `odin run` / `odin build`. |
| `add_post_build_step` | Append a hook that runs after a successful build/run. |
| `add_dependency` | Register a file path to copy into the profile output directory. Useful for copying libraries |
| `process` | Parse CLI args, resolve command + profile, and invoke the matching callback. |

### CLI

| Procedure | Description |
|-----------|-------------|
| `get_cli` | Parse `os.args` into positional args and `-key:value` / `--key:value` flags. |
| `dispose_cli` | Free the maps allocated by `get_cli`. |

### Execution

| Procedure | Description |
|-----------|-------------|
| `exec_cmd` | Run a builtin command: create output dir, install deps, pre steps, invoke `odin`, post steps (or `odin test` for `.Test`). |
| `run_script` | Execute a shell command string and stream its stdout/stderr. |
| `copy_to_output` | Copy a file or directory into `{profile.output}/{to}` (relative to the build driver root). |
```

### Delta release skeleton

```markdown
# Release Notes

- No need to mention the commit range

## What changed

- **Name** — consumer-facing description, tldr of the changes without having to look deeply at the different sections. This should be brief but to the point

## Fixes

- **Name** — what was broken and what users get now

## Changelog

### Types

| Name | Description |
|------|-------------|
| … | … |

### Added

| Procedure | Description |
|-----------|-------------|
| … | … |

### Removed

| Procedure |
|-----------|
| … | … |
```

In API tables for a delta: only new, changed, or removed symbols. Put signature/behavior changes in the Description column (e.g. new optional arg). Do not re-list the entire unchanged API.
