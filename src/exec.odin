/*
	Odin run/build/test execution: output dir, deps, pre/post steps,
	and the constructed odin command line.
*/
package rbs

import "core:fmt"
import "core:os"

Builtin_Command :: enum {
	Build,
	Run,
	Test,
}

/*
	Run a builtin command against a profile.

	* ctx - Build context (deps and pre/post steps)
	* cmd - Build, Run, or Test
	* profile - Target profile (entry, output, flags, platform)

	returns nil on success, or an Error from setup or execution
*/
exec_cmd :: proc(ctx: Context, cmd: Builtin_Command, profile: Profile) -> Error {
	if cmd == .Test {
		return exec_test(profile)
	}

	output_err := create_output(profile.output)
	if output_err != nil { return output_err }

	out := ensure_trailing_slash(profile.output)
	defer delete(out)

	install_dependencies(ctx, profile)

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

	script: string
	if profile.output != "" {
		if output_err := create_output(profile.output); output_err != nil {
			return output_err
		}
		out := ensure_trailing_slash(profile.output)
		defer delete(out)
		script = fmt.tprintf("odin test %s -out:%s%s %s", path, out, profile.name, flags)
	} else {
		script = fmt.tprintf("odin test %s -out:%s %s", path, profile.name, flags)
	}
	fmt.printfln("%s\n", script)

	return run_script(script)
}

@(private="file")
get_cmd_string :: proc(cmd: Builtin_Command) -> string {
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
