package rbs

import "core:fmt"
import "core:os/os2"
import "core:path/filepath"
import "core:strings"

@(private="package")
install_dependencies :: proc(ctx: Context, profile: Profile) -> Error {
    for dep in ctx.dependencies {
        if !os2.exists(dep) { return .Dependency_Does_Not_Exist }

        relative_path := strings.join({ profile.output, filepath.base(dep) }, "/")
        defer delete(relative_path)
        
        install_path, _ := filepath.abs(relative_path)
        defer delete(install_path)

        dep_path, _ := filepath.abs(dep)
        defer delete(dep_path)

        err := os2.copy_file(install_path, dep_path)
        if err != nil {
            fmt.eprintfln("Failed to copy %s, %s", dep, err)
            return err
        }
    }

    return nil
}

copy :: proc(p: Profile, from: string, to: string) -> Error {
    output_copy_dir := filepath.join({p.output, to})
    defer delete(output_copy_dir)

    return process_copy(from, from, output_copy_dir)
}

@(private="file")
process_copy :: proc(original_from: string, from: string, to: string) -> Error {
    if os2.is_dir(from) {
        extra := strings.trim_prefix(from, original_from)
        new_dir, _ := strings.concatenate({to, extra})
        defer delete(new_dir)

        if !os2.exists(new_dir) {
            err := os2.make_directory(new_dir)
            if err != nil {
                fmt.eprintf("Failed to create directory %s: %s", new_dir, err)
                return err
            }
        }

        dir, err := os2.open(from)
        if err != nil {
            fmt.eprintfln("Failed to open directory %s: %s", from, err)
            return err
        }

        defer os2.close(dir)

        files: []os2.File_Info
        files, err = os2.read_dir(dir, -1, context.allocator)
        if err != nil {
            fmt.eprintfln("Failed to read files from %s: %s", from, err)
            return err
        }
        defer delete(files)

        for file in files {
            defer os2.file_info_delete(file, context.allocator)
            name, _ := strings.replace(file.fullpath, "\\", "/", -1)
            defer delete(name)

            copy_err := process_copy(original_from, name, to)
            if copy_err != nil { return copy_err }
        }

        return nil
    }

    extra := strings.trim_prefix(from, original_from)
    real_to := strings.concatenate({to, extra})
    defer delete(real_to)
    
    copy_err := os2.copy_file(real_to, from)
    if copy_err != nil {
        fmt.eprintfln("Failed to copy: %s", copy_err)
        return copy_err
    }

    return nil
}