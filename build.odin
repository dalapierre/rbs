package build

import "core:os"
import "core:fmt"
import rbs "src"

main :: proc() {
    ctx := rbs.init_context()
    defer rbs.dispose_context(ctx)

    rbs.add_profile(&ctx, "default", {
        arch    = ODIN_ARCH,
        entry   = "src",
        mode    = .Executable,
        name    = "rbs_test",
        os      = ODIN_OS,
    })

    rbs.add_profile(&ctx, "ci", {
        arch    = ODIN_ARCH,
        entry   = ".",
        mode    = .Executable,
        os      = ODIN_OS,
        output  = "bin"
    })

    rbs.add_command(&ctx, "test", run_tests)
    rbs.add_command(&ctx, "install", run_ci)

    if err := rbs.process(ctx); err != nil {
        os.exit(1)
    }
}

run_tests :: proc(ctx: rbs.Context, p: rbs.Profile) { rbs.exec_cmd(ctx, .Test, p) }

run_ci :: proc(ctx: rbs.Context, p: rbs.Profile) {
    opt := rbs.Copy_Option{pattern = "_test", mode = .Exclude}
    rbs.copy_to_output(p, "src", "rbs", &opt)
}