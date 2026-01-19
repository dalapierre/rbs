# rbs

RBS Stands for `Rune Build System`. It is a way to define build profiles for Odin projects and is an iteration over the [Rune](https://github.com/dalapierre/rune) CLI I previously built.

### Purpose

Having to write scripts or Makefiles to build projects can be annoying, especially if you need to support multiple architectures and OS. The goal of this project is to facilitate the development of a build system for Odin projects through custom CLI tools.

### How it works

The idea is that you create a simply odin file (usually called `rbs.odin`) that you place at the root of your project. From there, you can run the command `odin build . -out:rune.exe` (.exe if you are on windows). The result, is a build system that you can use by calling `./rune` from the root of your project.

#### Basic rds.odin definition

First, you need to either clone or add the `rbs` package to the root of your project. Then, you create a `rbs.odin` file and paste the following code:

```odin
package build

import "rds"

main :: proc() {
    ctx := rbs.init_context()
    defer rbs.dispose_context(ctx)

    // define a profile, the first one is always the default
    rbs.add_profile(&ctx, DEBUG_PROFILE, {
        entry = "src",          // path to the entry point of your package
        flags = "-vet -debug",  // some flags
        mode = .Executable,     // output type
        name = "wrath",         // name of your project
        output = "bin",         // output path
        arch = ODIN_ARCH,       // architecture of the profile, in this case, the current platform
        os = ODIN_OS            // os of the profile, in this case, the current os
    })

    // default command if you run ./rune
    rbs.add_command(ctx, "", proc(ctx: rbs.Context, p: rbs.Profile) { rbs.exec_odin_cmd(ctx, .Run, p) })
    // run command if you run ./rune run
    rbs.add_command(ctx, "run", proc(ctx: rbs.Context, p: rbs.Profile) { rbs.exec_odin_cmd(ctx, .Run, p) })
    // build command if you run ./rune build
    rbs.add_command(ctx, "build", proc(ctx: rbs.Context, p: rbs.Profile) { rbs.exec_odin_cmd(ctx, .Build, p) })


    // process the build by looking at the arguments passed to the CLI
    rbs.process(ctx)
}

```

From there, you can build the file and should be able to call `./rune`, `./rune run` and `./rune build`.

#### How to extend

You can define a new profile by adding new profiles using `rbs.add_profile(...)`. You can specify which profile to use by adding the profile name after the command, e.g. `./rune run my_release_profile`

You can also have access to CLI flags and arguments by using the `rbs.get_cli(os.args)` command. This will return a list of args and flags with their values, this way you can specify custom rules such as:

```odin

// called through ./rune run -scn:some_scene

process_flags :: proc(ctx: ^rbs.Context) {
    cli := rbs.get_cli(os2.args)
    defer rbs.dispose_cli(cli)

    if "scn" in cli.flags {
        p := rbs.get_profile(ctx^, DEBUG_PROFILE)
        f_room := fmt.aprintf("%s=%s", "-define:SCENE", cli.flags[SCENE_FLAG])
        p.flags = fmt.aprintf("%s %s", p.flags, f_room)
    }
}

```


### Other features

- Install depenencies such as dlls through `rbs.add_dependency(&ctx, "some_path")`
- Run scripts through `rbs.run_script("your script")`
- Add prebuild steps through `rbs.add_pre_build_step`
- Add post build steps through `rbs.add_post_build_step`

### RCP (Rune Content Pipeline)

The pipeline is currently in development and is at the early stages. It is meant to define how to process certain assets such as shaders when making games. It also caches assets under `.rcp-cache` so that they are not reprocessed unless they change.