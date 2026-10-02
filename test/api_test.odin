// Unit tests for the public rbs API (context, profiles,
// commands, CLI, deps, process).
package test

import "base:runtime"
import "core:os"
import "core:path/filepath"
import "core:testing"

import rbs "../src"

@(test)
test_init_and_dispose_context :: proc(t: ^testing.T) {
	ctx := rbs.init_context()
	defer rbs.dispose_context(ctx)

	testing.expect_value(t, len(ctx.profiles), 0)
	testing.expect_value(t, len(ctx.commands), 0)
	testing.expect_value(t, len(ctx.pre_build_steps), 0)
	testing.expect_value(t, len(ctx.post_build_steps), 0)
	testing.expect_value(t, len(ctx.dependencies), 0)
	testing.expect_value(t, ctx.default_profile, "")
}

@(test)
test_add_and_get_profile :: proc(t: ^testing.T) {
	ctx := rbs.init_context()
	defer rbs.dispose_context(ctx)

	debug := rbs.Profile{
		flags  = "-debug",
		name   = "demo",
		output = "bin",
		entry  = "src",
		mode   = .Executable,
		os     = .Linux,
		arch   = .amd64,
	}
	release := rbs.Profile{
		flags  = "-o:speed",
		name   = "demo",
		output = "bin",
		entry  = "src",
		mode   = .Executable,
		os     = .Linux,
		arch   = .amd64,
	}

	rbs.add_profile(&ctx, "debug", debug)
	testing.expect_value(t, ctx.default_profile, "debug")

	rbs.add_profile(&ctx, "release", release)
	testing.expect_value(t, ctx.default_profile, "debug")
	testing.expect_value(t, len(ctx.profiles), 2)

	got, ok := rbs.get_profile(ctx, "debug")
	testing.expect(t, ok)
	testing.expect_value(t, got.flags, "-debug")
	testing.expect_value(t, got.name, "demo")
	testing.expect_value(t, got.output, "bin")
	testing.expect_value(t, got.entry, "src")
	testing.expect_value(t, got.mode, runtime.Odin_Build_Mode_Type.Executable)
	testing.expect_value(t, got.os, runtime.Odin_OS_Type.Linux)
	testing.expect_value(t, got.arch, runtime.Odin_Arch_Type.amd64)

	got, ok = rbs.get_profile(ctx, "release")
	testing.expect(t, ok)
	testing.expect_value(t, got.flags, "-o:speed")
}

@(test)
test_get_profile_missing :: proc(t: ^testing.T) {
	ctx := rbs.init_context()
	defer rbs.dispose_context(ctx)

	_, ok := rbs.get_profile(ctx, "missing")
	testing.expect(t, !ok)
}

@(test)
test_add_command :: proc(t: ^testing.T) {
	ctx := rbs.init_context()
	defer rbs.dispose_context(ctx)

	noop :: proc(ctx: rbs.Context, p: rbs.Profile) {}

	rbs.add_command(&ctx, "", noop)
	rbs.add_command(&ctx, "build", noop)
	rbs.add_command(&ctx, "run", noop)

	testing.expect_value(t, len(ctx.commands), 3)
	testing.expect(t, "" in ctx.commands)
	testing.expect(t, "build" in ctx.commands)
	testing.expect(t, "run" in ctx.commands)
}

@(test)
test_add_pre_and_post_build_steps :: proc(t: ^testing.T) {
	ctx := rbs.init_context()
	defer rbs.dispose_context(ctx)

	step :: proc(ctx: rbs.Context, p: rbs.Profile) {}

	rbs.add_pre_build_step(&ctx, step)
	rbs.add_pre_build_step(&ctx, step)
	rbs.add_post_build_step(&ctx, step)

	testing.expect_value(t, len(ctx.pre_build_steps), 2)
	testing.expect_value(t, len(ctx.post_build_steps), 1)
}

@(test)
test_add_dependency :: proc(t: ^testing.T) {
	ctx := rbs.init_context()
	defer rbs.dispose_context(ctx)

	rbs.add_dependency(&ctx, "libs/foo.so")
	rbs.add_dependency(&ctx, "libs/bar.so")

	testing.expect_value(t, len(ctx.dependencies), 2)
	testing.expect_value(t, ctx.dependencies[0], "libs/foo.so")
	testing.expect_value(t, ctx.dependencies[1], "libs/bar.so")
}

@(test)
test_get_cli_args_and_flags :: proc(t: ^testing.T) {
	args := []string{
		"rune",
		"run",
		"debug",
		"-scn:main_menu",
		"--verbose",
		"-flag",
		"--define:FOO=bar",
	}

	cli := rbs.get_cli(args)
	defer rbs.dispose_cli(cli)

	testing.expect_value(t, len(cli.args), 2)
	testing.expect_value(t, cli.args[0], "run")
	testing.expect_value(t, cli.args[1], "debug")

	testing.expect_value(t, cli.flags["scn"], "main_menu")
	testing.expect_value(t, cli.flags["verbose"], "true")
	testing.expect_value(t, cli.flags["flag"], "true")
	testing.expect_value(t, cli.flags["define"], "FOO=bar")
}

@(test)
test_get_cli_skips_program_name :: proc(t: ^testing.T) {
	args := []string{"./rune", "build"}

	cli := rbs.get_cli(args)
	defer rbs.dispose_cli(cli)

	testing.expect_value(t, len(cli.args), 1)
	testing.expect_value(t, cli.args[0], "build")
	testing.expect_value(t, len(cli.flags), 0)
}

@(test)
test_get_cli_empty_args :: proc(t: ^testing.T) {
	cli := rbs.get_cli([]string{"rune"})
	defer rbs.dispose_cli(cli)

	testing.expect_value(t, len(cli.args), 0)
	testing.expect_value(t, len(cli.flags), 0)
}

@(test)
test_run_script_success :: proc(t: ^testing.T) {
	err := rbs.run_script("true")
	testing.expect(t, err == nil)
}

@(test)
test_copy_file_into_profile_output :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	src_dir, src_dir_err := filepath.join({tmp, "assets"}, context.allocator)
	testing.expect(t, src_dir_err == nil)
	defer delete(src_dir)
	testing.expect(t, os.make_directory(src_dir) == nil)

	src_file, src_file_err := filepath.join({src_dir, "note.txt"}, context.allocator)
	testing.expect(t, src_file_err == nil)
	defer delete(src_file)
	testing.expect(t, os.write_entire_file(src_file, "hello") == nil)

	out_dir, out_dir_err := filepath.join({tmp, "bin"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, os.make_directory(out_dir) == nil)

	profile := rbs.Profile{
		output = out_dir,
		name   = "demo",
		entry  = "src",
		mode   = .Executable,
		os     = ODIN_OS,
		arch   = ODIN_ARCH,
	}

	err := rbs.copy(profile, src_file, "note.txt")
	testing.expect(t, err == nil)

	// copy of a single file writes to {output}/{to}
	copied, copied_err := filepath.join({out_dir, "note.txt"}, context.allocator)
	testing.expect(t, copied_err == nil)
	defer delete(copied)
	testing.expect(t, os.exists(copied))

	content, read_err := os.read_entire_file_from_path(copied, context.allocator)
	defer delete(content)
	testing.expect(t, read_err == nil)
	testing.expect_value(t, string(content), "hello")
}

@(test)
test_copy_directory_into_profile_output :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	src_dir, src_dir_err := filepath.join({tmp, "assets"}, context.allocator)
	testing.expect(t, src_dir_err == nil)
	defer delete(src_dir)
	testing.expect(t, os.make_directory(src_dir) == nil)

	nested, nested_err := filepath.join({src_dir, "nested"}, context.allocator)
	testing.expect(t, nested_err == nil)
	defer delete(nested)
	testing.expect(t, os.make_directory(nested) == nil)

	src_file, src_file_err := filepath.join({nested, "a.txt"}, context.allocator)
	testing.expect(t, src_file_err == nil)
	defer delete(src_file)
	testing.expect(t, os.write_entire_file(src_file, "nested") == nil)

	out_dir, out_dir_err := filepath.join({tmp, "bin"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, os.make_directory(out_dir) == nil)

	profile := rbs.Profile{
		output = out_dir,
		name   = "demo",
		entry  = "src",
		mode   = .Executable,
		os     = ODIN_OS,
		arch   = ODIN_ARCH,
	}

	err := rbs.copy(profile, src_dir, "copied")
	testing.expect(t, err == nil)

	copied, copied_err := filepath.join({out_dir, "copied", "nested", "a.txt"}, context.allocator)
	testing.expect(t, copied_err == nil)
	defer delete(copied)
	testing.expect(t, os.exists(copied))
}
