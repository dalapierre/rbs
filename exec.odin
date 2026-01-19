package rbs

import "core:fmt"

Odin_Command :: enum {
    Build,
    Run
}

// Run the project
exec_odin_cmd :: proc(ctx: Context, cmd: Odin_Command, profile: Profile) -> Error {
    output_err := create_output(profile.output)
    if output_err != nil { return output_err }
    
    out := ensure_trailing_slash(profile.output)
    defer delete(out)

    install_dependencies(ctx, profile)

    // run pre build
    for step in ctx.pre_build_steps {
        step(ctx, profile)
    }

    ext, _ := get_extension(profile.os, profile.mode)
    s_cmd := get_cmd_string(cmd)

    script := fmt.tprintf("odin %s %s -out:%s%s%s -target:%s %s", s_cmd, profile.entry, out, profile.name, ext, get_platform(profile.arch, profile.os), profile.flags)
    fmt.printfln("%s\n", script)
    
    e := run_script(script)
    if e != nil { return e }

    // run post build
    for step in ctx.post_build_steps {
        step(ctx, profile)
    }

    return nil
}

@(private="file")
get_cmd_string :: proc(cmd: Odin_Command) -> string {
    switch cmd {
        case .Build:
            return "build"
        case .Run:
            return "run"
    }

    return "INVALID"
}