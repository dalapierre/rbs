// Tests for build context: profiles, commands, deps, and steps.
package rbs

import "base:runtime"
import "core:testing"

@(test)
test_init_and_dispose_context :: proc(t: ^testing.T) {
	ctx := init_context()
	defer dispose_context(ctx)

	testing.expect_value(t, len(ctx.profiles), 0)
	testing.expect_value(t, len(ctx.commands), 0)
	testing.expect_value(t, len(ctx.pre_build_steps), 0)
	testing.expect_value(t, len(ctx.post_build_steps), 0)
	testing.expect_value(t, len(ctx.dependencies), 0)
	testing.expect_value(t, ctx.default_profile, "")
}

@(test)
test_add_and_get_profile :: proc(t: ^testing.T) {
	ctx := init_context()
	defer dispose_context(ctx)

	debug := Profile{
		flags  = "-debug",
		name   = "demo",
		output = "bin",
		entry  = "src",
		mode   = .Executable,
		os     = .Linux,
		arch   = .amd64,
	}
	release := Profile{
		flags  = "-o:speed",
		name   = "demo",
		output = "bin",
		entry  = "src",
		mode   = .Executable,
		os     = .Linux,
		arch   = .amd64,
	}

	add_profile(&ctx, "debug", debug)
	testing.expect_value(t, ctx.default_profile, "debug")

	add_profile(&ctx, "release", release)
	testing.expect_value(t, ctx.default_profile, "debug")
	testing.expect_value(t, len(ctx.profiles), 2)

	got, ok := get_profile(ctx, "debug")
	testing.expect(t, ok)
	testing.expect_value(t, got.flags, "-debug")
	testing.expect_value(t, got.name, "demo")
	testing.expect_value(t, got.output, "bin")
	testing.expect_value(t, got.entry, "src")
	testing.expect_value(t, got.mode, runtime.Odin_Build_Mode_Type.Executable)
	testing.expect_value(t, got.os, runtime.Odin_OS_Type.Linux)
	testing.expect_value(t, got.arch, runtime.Odin_Arch_Type.amd64)

	got, ok = get_profile(ctx, "release")
	testing.expect(t, ok)
	testing.expect_value(t, got.flags, "-o:speed")
}

@(test)
test_get_profile_missing :: proc(t: ^testing.T) {
	ctx := init_context()
	defer dispose_context(ctx)

	_, ok := get_profile(ctx, "missing")
	testing.expect(t, !ok)
}

@(test)
test_add_command :: proc(t: ^testing.T) {
	ctx := init_context()
	defer dispose_context(ctx)

	noop :: proc(ctx: Context, p: Profile) {}

	add_command(&ctx, "", noop)
	add_command(&ctx, "build", noop)
	add_command(&ctx, "run", noop)

	testing.expect_value(t, len(ctx.commands), 3)
	testing.expect(t, "" in ctx.commands)
	testing.expect(t, "build" in ctx.commands)
	testing.expect(t, "run" in ctx.commands)
}

@(test)
test_add_pre_and_post_build_steps :: proc(t: ^testing.T) {
	ctx := init_context()
	defer dispose_context(ctx)

	step :: proc(ctx: Context, p: Profile) {}

	add_pre_build_step(&ctx, step)
	add_pre_build_step(&ctx, step)
	add_post_build_step(&ctx, step)

	testing.expect_value(t, len(ctx.pre_build_steps), 2)
	testing.expect_value(t, len(ctx.post_build_steps), 1)
}

@(test)
test_add_dependency :: proc(t: ^testing.T) {
	ctx := init_context()
	defer dispose_context(ctx)

	add_dependency(&ctx, "libs/foo.so")
	add_dependency(&ctx, "libs/bar.so")

	testing.expect_value(t, len(ctx.dependencies), 2)
	testing.expect_value(t, ctx.dependencies[0], "libs/foo.so")
	testing.expect_value(t, ctx.dependencies[1], "libs/bar.so")
}
