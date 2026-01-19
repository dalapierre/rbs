package rbs

import "core:fmt"
import "core:os/os2"
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

init_context :: proc() -> Context {
    return {
        commands            = make(map[string]Command),
        profiles            = make(map[string]Profile),
        pre_build_steps     = make([dynamic]Command),
        post_build_steps    = make([dynamic]Command),
        dependencies        = make([dynamic]string)
    }
}

add_command :: proc(ctx: ^Context, cmd: string, p: proc(Context, Profile)) {
    ctx.commands[cmd] = p
}

add_profile :: proc(ctx: ^Context, name: string, p: Profile) {
    ctx.profiles[name] = p
    if ctx.default_profile == "" {
        ctx.default_profile = name
    }
}

get_profile :: proc(ctx: Context, name: string) -> ^Profile {
    if !(name in ctx.profiles) {
        return nil
    }
    
    return &ctx.profiles[name]
}

dispose_context :: proc(ctx: Context) {
    delete(ctx.commands)
    delete(ctx.profiles)
    delete(ctx.pre_build_steps)
    delete(ctx.post_build_steps)
    delete(ctx.dependencies)
}

add_pre_build_step :: proc(ctx: ^Context, cmd: Command) {
    append(&ctx.pre_build_steps, cmd)
}

add_post_build_step :: proc(ctx: ^Context, cmd: Command) {
    append(&ctx.post_build_steps, cmd)
}

add_dependency :: proc(ctx: ^Context, dep: string) { append(&ctx.dependencies, dep) }

process :: proc(ctx: Context) -> Error {
    cli := get_cli(os2.args)
    defer dispose_cli(cli)

    // get profile or first added
    cmd := len(cli.args) == 0 ? "" : cli.args[0]
    if !(cmd in ctx.commands) {
        fmt.eprintfln("Command %s was not registered", cmd)
        return .Command_Not_Found
    }

    profile_name := len(cli.args) >= 2? cli.args[1] : ctx.default_profile
    profile := get_profile(ctx, profile_name)
    if profile == nil {
        fmt.eprintfln("Profile %s was not registered", profile_name)
        return .Profile_Not_Found
    }

    p := ctx.commands[cmd]
    p(ctx, profile^)

    return nil
}