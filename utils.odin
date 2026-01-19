package rbs

import "core:strings"
import "core:os/os2"
import "core:fmt"

@(private="package")
create_output :: proc(output: string) -> Error {
    dirs, _ := strings.split(output, "/")
    defer delete(dirs)

    curr := strings.clone(".")
    defer delete(curr)

    for dir in dirs {
        new_curr, _ := strings.concatenate({ curr, "/", dir })
        delete(curr)
        curr = new_curr

        if !os2.exists(curr) {
            err := os2.make_directory(curr)
            if err != nil {
                fmt.eprintfln("Error occurred while trying to create output directory %s", curr)
                return err
            }
        }
    }

    return nil
}

@(private="package")
ensure_trailing_slash :: proc(path: string) -> string {
    if strings.has_suffix(path, "/") {
        return strings.clone(path)
    }
    return fmt.aprintf("%s/", path)
}