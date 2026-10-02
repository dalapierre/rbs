// Odin run/build/test execution: output dir, deps, pre/post steps,
// and the constructed odin command line.
package rbs

import "core:fmt"
import "core:os"

Odin_Command :: enum {
	Build,
	Run,
	Test,
}

// Run the project (build/run) or execute tests via `odin test`.
exec_odin_cmd :: proc(ctx: Context, cmd: Odin_Command, profile: Profile) -> Error {
	if cmd == .Test {
		return exec_test(profile)
	}

	output_err := create_output(profile.output)
	if output_err != nil { return output_err }

	out := ensure_trailing_slash(profile.output)
	defer delete(out)

	install_dependencies(ctx, profile)

	// run pre build
	for step in ctx.pre_build_steps {
		step(ctx, profile)
	}

	s_cmd := get_cmd_string(cmd)
	ext, _ := get_extension(profile.os, profile.mode)
	script := fmt.tprintf(
		"odin %s %s -out:%s%s%s -target:%s %s",
		s_cmd, profile.entry, out, profile.name, ext, get_platform(profile.arch, profile.os), profile.flags,
	)
	fmt.printfln("%s\n", script)

	if exec_err := run_script(script); exec_err != nil do return exec_err

	// run post build
	for step in ctx.post_build_steps {
		step(ctx, profile)
	}

	return nil
}

@(private="file")
exec_test :: proc(profile: Profile) -> Error {
	cli := get_cli(os.args)
	defer dispose_cli(cli)

	opts, opts_err := parse_test_options(cli.flags)
	if opts_err != nil do return opts_err

	path, file_mode := resolve_test_path(opts, profile.entry)
	defer delete(path)

	flags := append_test_flags(profile.flags, opts, file_mode)
	defer delete(flags)

	script := fmt.tprintf("odin test %s %s", path, flags)
	fmt.printfln("%s\n", script)

	return run_script(script)
}

@(private="file")
get_cmd_string :: proc(cmd: Odin_Command) -> string {
	switch cmd {
		case .Build:
			return "build"
		case .Run:
			return "run"
		case .Test:
			return "test"
	}

	return "INVALID"
}
