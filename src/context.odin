/*
	Build context: profiles, commands, deps, pre/post steps,
	and process() dispatch from CLI args.
*/
package rbs

import "core:fmt"
import "core:os"
import "base:runtime"

@(private="package")
RUN     :: "run"
@(private="package")
BUILD   :: "build"

Command     :: proc(ctx: Context, p: Profile)

Context :: struct {
    profiles:           map[string]Profile,
    commands:           map[string]Command,
    pre_build_steps:    [dynamic]Command,
    post_build_steps:   [dynamic]Command,
    dependencies:       [dynamic]string,
    default_profile:    string
}

Profile :: struct {
    flags:  string,
    name:   string,
    output: string,
    entry:  string,
    mode:   runtime.Odin_Build_Mode_Type,
    os:     runtime.Odin_OS_Type,
    arch:   runtime.Odin_Arch_Type
}

/*
	Allocate an empty build context.

	returns an empty context ready for profiles and commands
*/
init_context :: proc() -> Context {
    return {
        commands            = make(map[string]Command),
        profiles            = make(map[string]Profile),
        pre_build_steps     = make([dynamic]Command),
        post_build_steps    = make([dynamic]Command),
        dependencies        = make([dynamic]string)
    }
}

/*
	Register a named command handler.

	* ctx - Context to mutate
	* cmd - Command name (first CLI arg)
	* p - Handler invoked with the resolved profile
*/
add_command :: proc(ctx: ^Context, cmd: string, p: proc(Context, Profile)) {
    ctx.commands[cmd] = p
}

/*
	Register a named build profile. The first added becomes the default.

	* ctx - Context to mutate
	* name - Profile key used on the CLI
	* p - Profile configuration
*/
add_profile :: proc(ctx: ^Context, name: string, p: Profile) {
    ctx.profiles[name] = p

    if ctx.default_profile == "" {
        ctx.default_profile = name
    }
}

/*
	Look up a profile by name.

	* ctx - Context to search
	* name - Profile key

	returns the profile and true if found, otherwise {}, false
*/
get_profile :: proc(ctx: Context, name: string) -> (Profile, bool) {
    if !(name in ctx.profiles) {
        return {}, false
    }
    
    return ctx.profiles[name], true
}

/*
	Free maps and slices owned by the context.

	* ctx - Context previously returned from init_context
*/
dispose_context :: proc(ctx: Context) {
    delete(ctx.commands)
    delete(ctx.profiles)
    delete(ctx.pre_build_steps)
    delete(ctx.post_build_steps)
    delete(ctx.dependencies)
}

/*
	Append a step run before the odin build/run command.

	* ctx - Context to mutate
	* cmd - Step callback
*/
add_pre_build_step :: proc(ctx: ^Context, cmd: Command) {
    append(&ctx.pre_build_steps, cmd)
}

/*
	Append a step run after a successful odin build/run command.

	* ctx - Context to mutate
	* cmd - Step callback
*/
add_post_build_step :: proc(ctx: ^Context, cmd: Command) {
    append(&ctx.post_build_steps, cmd)
}

/*
	Register a dependency path to copy into the profile output.

	* ctx - Context to mutate
	* dep - Filesystem path of the dependency
*/
add_dependency :: proc(ctx: ^Context, dep: string) { append(&ctx.dependencies, dep) }

/*
	Parse CLI args, resolve command + profile, and invoke the handler.

	* ctx - Fully configured build context

	returns nil on success, or an Error if command/profile is missing
*/
process :: proc(ctx: Context) -> Error {
    cli := get_cli(os.args)
    defer dispose_cli(cli)

    cmd := len(cli.args) == 0 ? "" : cli.args[0]
    if !(cmd in ctx.commands) {
        fmt.eprintfln("Command %s was not registered", cmd)
        return .Command_Not_Found
    }

    profile_name := len(cli.args) >= 2? cli.args[1] : ctx.default_profile
    profile, ok := get_profile(ctx, profile_name)
    if !ok {
        fmt.eprintfln("Profile %s was not registered", profile_name)
        return .Profile_Not_Found
    }

    p := ctx.commands[cmd]
    p(ctx, profile)

    return nil
}
