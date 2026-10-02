package build

import "core:os"
import "core:fmt"
import rbs "src"

main :: proc() {
    ctx := rbs.init_context()
    defer rbs.dispose_context(ctx)

    rbs.add_profile(&ctx, "default", {
        arch    = ODIN_ARCH,
        entry   = "tests",
        mode    = .Executable,
        os      = ODIN_OS,
    })

    rbs.add_command(&ctx, "test", run_tests)

    if err := rbs.process(ctx); err != nil {
        fmt.eprintfln("%s", err)
        os.exit(1)
    }
}

run_tests :: proc(ctx: rbs.Context, p: rbs.Profile) { rbs.exec_odin_cmd(ctx, .Test, p) }