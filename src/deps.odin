package rbs

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

@(private="package")
install_dependencies :: proc(ctx: Context, profile: Profile) -> Error {
    for dep in ctx.dependencies {
        if !os.exists(dep) { return .Dependency_Does_Not_Exist }

        relative_path := strings.join({ profile.output, filepath.base(dep) }, "/")
        defer delete(relative_path)
        
        install_path, _ := filepath.abs(filepath.dir(relative_path), context.allocator)
        defer delete(install_path)

        full_path := fmt.aprintf("%s/%s", install_path, filepath.base(relative_path))
        defer delete(full_path)

        dep_path, _ := filepath.abs(dep, context.allocator)
        defer delete(dep_path)

        if err := os.copy_file(full_path, dep_path); err != nil {
            fmt.eprintfln("Failed to copy %s, %s", dep, err)
            return err
        }
    }

    return nil
}

copy :: proc(p: Profile, from: string, to: string) -> Error {
    output_copy_dir, err := filepath.join({p.output, to}, context.allocator)
    if err != nil do return err
    defer delete(output_copy_dir)

    return process_copy(from, from, output_copy_dir)
}

@(private="file")
process_copy :: proc(original_from: string, from: string, to: string) -> Error {
    if os.is_dir(from) {
        extra := strings.trim_prefix(from, original_from)
        new_dir, _ := strings.concatenate({to, extra})
        defer delete(new_dir)

        if !os.exists(new_dir) {
            err := os.make_directory(new_dir)
            if err != nil {
                fmt.eprintf("Failed to create directory %s: %s", new_dir, err)
                return err
            }
        }

        dir, err := os.open(from)
        if err != nil {
            fmt.eprintfln("Failed to open directory %s: %s", from, err)
            return err
        }

        defer os.close(dir)

        files: []os.File_Info
        files, err = os.read_dir(dir, -1, context.allocator)
        if err != nil {
            fmt.eprintfln("Failed to read files from %s: %s", from, err)
            return err
        }
        defer delete(files)

        for file in files {
            defer os.file_info_delete(file, context.allocator)
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
    
    copy_err := os.copy_file(real_to, from)
    if copy_err != nil {
        fmt.eprintfln("Failed to copy: %s", copy_err)
        return copy_err
    }

    return nil
}