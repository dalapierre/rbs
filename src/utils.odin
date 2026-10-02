// Small shared path helpers: build-program root resolution,
// nested output dirs, and trailing-slash normalization.
package rbs

import "core:strings"
import "core:os"
import "core:fmt"
import "core:path/filepath"

// Directory containing the build driver (rbs / rune), i.e. where
// the build file lives when the binary is built next to it.
@(private="package")
get_build_root :: proc(allocator := context.allocator) -> (string, Error) {
	exe_abs, err := filepath.abs(os.args[0], allocator)
	if err != nil do return "", err
	defer delete(exe_abs, allocator)
	return strings.clone(filepath.dir(exe_abs), allocator), nil
}

// Resolve path against the build program root when relative.
// Absolute paths are returned cloned unchanged.
@(private="package")
resolve_build_path :: proc(path: string, allocator := context.allocator) -> (string, Error) {
	if path == "" {
		return get_build_root(allocator)
	}
	if filepath.is_abs(path) {
		return strings.clone(path, allocator), nil
	}

	root, err := get_build_root(allocator)
	if err != nil do return "", err
	defer delete(root, allocator)

	return filepath.join({root, path}, allocator)
}

// Create the output directory if needed. No-op when it already exists
// (`os.make_directory_all` returns `.Exist` in that case on some platforms).
create_output :: proc(output: string) -> Error {
	if output == "" do return nil

	abs_out, err := resolve_build_path(output)
	if err != nil do return err
	defer delete(abs_out)

	if dir_err := os.make_directory_all(abs_out); dir_err != nil && dir_err != .Exist {
		fmt.eprintfln("Error occurred while trying to create output directory %s", abs_out)
		return dir_err
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