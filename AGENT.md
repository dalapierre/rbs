# AGENT.md — Rune Build System (rbs)

Odin library that lets projects define build profiles and CLI commands in a root `rbs.odin`, then compile that file into a `./rune` (or `rune.exe`) driver. Still in development. Successor ideas from [Rune](https://github.com/dalapierre/rune).

## Layout

| Path | Role |
|------|------|
| `src/` | `package rbs` — core API and co-located `*_test.odin` tests |
| `ols.json` | OLS checker paths: `src`, `build.odin` |

## Consumer model

Users vendor/clone this package, write `rbs.odin` with `package build`, call `rbs.init_context` / `add_profile` / `add_command` / `process`, then:

```text
odin build . -out:rune
./rune [command] [profile] [flags...]
```

- First registered profile is the default.
- CLI shape: `./rune <cmd> [profile]`; flags via `-key:value` / `--key:value` (`get_cli` / `dispose_cli`).
- Typical commands wire to `exec_cmd(ctx, .Run|.Build, profile)`.

## Core API (`package rbs`)

- **Context**: profiles, commands, pre/post build steps, dependency paths, `default_profile`
- **Profile**: `flags`, `name`, `output`, `entry`, `mode`, `os`, `arch` (`runtime.Odin_*` types)
- Register: `add_profile`, `add_command`, `add_pre_build_step`, `add_post_build_step`, `add_dependency`
- Run: `process` → resolve command + profile → invoke `Command` proc
- Build: `exec_cmd` creates output dir, installs deps, pre steps, `odin run|build … -target:…`, post steps
- Helpers: `run_script`, `copy_to_output` (from build-root → profile output), platform/extension helpers in `platform.odin`
- Errors: `Error` union (`os.Error` | `RBS_Error` | `Allocator_Error`)

## File ownership (one concern per file)

Each `.odin` file is its own content context. Put new code in the existing file that owns that concern, or create a new file when the concept is distinct.

Examples: CLI parsing → `cli.odin`; context/profiles/commands → `context.odin`; odin run/build orchestration → `exec.odin`; a new “test” exec mode stays in `exec.odin`, but test-only helpers/types would go in a new `testing.odin`.

Current owners (`src/`): `cli`, `context`, `deps`, `errors`, `exec`, `platform`, `scripting`, `testing`, `utils`.

**Required:** every new `.odin` file must start with a multi-line top comment (≤80 chars per line) stating the file’s purpose. Existing files already follow this.

## Conventions for changes

- Language: **Odin**. Match existing style (tabs in tests, `:: proc`, package-level privacy with `@(private="package"|"file")`).
- Prefer extending public procs on `Context`/`Profile` over changing CLI parsing semantics without tests.
- Tests live in `src/` as `*_test.odin` siblings (same `package rbs`) so package-private APIs are testable. Each owner file should have a matching `*_test.odin`.
- Odin excludes `*_test.odin` from normal builds; only `odin test` compiles them.
- If a test uses `core:os` to create files or directories, always clean them up after the test (e.g. `defer os.remove_all(tmp)`), so nothing is left behind in CI or locally.
- Do not commit build artifacts (`bin/`, `*.exe`).
- README examples may say `rds` — the real package name is **`rbs`**.

## Required: verify after every code change

After any new or changed code is complete, run the test suite and read the full output before considering the task done:

```text
// prerequisite, run `odin build .` from root to make sure rbs is built
./rbs test
```

to run a specific test use rbs through
```text
./rbs test -t:{testName}
```

**Completion criteria** — both must be true:

1. **All tests pass** (no failing assertions / test failures).
2. **No memory failures** (leaks, use-after-free, double-free, allocator errors, or other memory diagnostics in the output).

If a memory issue appears, the task is **not complete** until it is fixed and a re-run is clean. Do not stop at “tests passed” if memory errors are present.
