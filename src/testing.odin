/*
	Test CLI helpers for `odin test`.
	Resolves -t/-f/-p and the profile entry path.
*/
package rbs

import "core:fmt"
import "core:strings"

@(private="file")
TEST_FLAG :: "t"
@(private="file")
FILE_FLAG :: "f"
@(private="file")
PACKAGE_FLAG :: "p"
@(private="file")
DEFAULT_FLAG_VAL :: "true"

// Options derived from CLI flags for a test run.
Test_Options :: struct {
	test_name:    string, // -t:<name>, empty if unset
	file:         string, // -f:<file>, empty if unset
	package_path: string, // -p:<package>, empty if unset
}

// Resolve -t / -f / -p from a parsed CLI. Returns an error if a flag
// is present without a value (e.g. bare `-t`).
parse_test_options :: proc(flags: map[string]string) -> (Test_Options, Error) {
	opts: Test_Options

	if TEST_FLAG in flags {
		if flags[TEST_FLAG] == DEFAULT_FLAG_VAL {
			fmt.eprintln("Invalid test name. Make sure it is formatted -t:<test_name>")
			return {}, .Invalid_Test_Flag
		}
		opts.test_name = flags[TEST_FLAG]
	}

	if FILE_FLAG in flags {
		if flags[FILE_FLAG] == DEFAULT_FLAG_VAL {
			fmt.eprintln("Invalid file name. Make sure it is formatted -f:<file_name>")
			return {}, .Invalid_File_Flag
		}
		opts.file = flags[FILE_FLAG]
	}

	if PACKAGE_FLAG in flags {
		if flags[PACKAGE_FLAG] == DEFAULT_FLAG_VAL {
			fmt.eprintln("Invalid package name. Make sure it is formatted -p:<package_name>")
			return {}, .Invalid_Package_Flag
		}
		opts.package_path = flags[PACKAGE_FLAG]
	}

	return opts, nil
}

// Pick the path passed to `odin test`.
// Priority: -f > -p > profile `entry`.
resolve_test_path :: proc(
	opts: Test_Options,
	entry: string,
	allocator := context.allocator,
) -> (path: string, file_mode: bool) {
	if opts.file != "" {
		return strings.clone(opts.file, allocator), true
	}
	if opts.package_path != "" {
		return strings.clone(opts.package_path, allocator), false
	}
	return strings.clone(entry, allocator), false
}

@(private="package")
append_test_flags :: proc(
	base_flags: string,
	opts: Test_Options,
	file_mode: bool,
	allocator := context.allocator,
) -> string {
	parts := make([dynamic]string, allocator)
	defer delete(parts)

	if base_flags != "" {
		append(&parts, base_flags)
	}
	if file_mode {
		append(&parts, "-file")
	}
	if opts.test_name != "" {
		append(&parts, fmt.tprintf("-define:ODIN_TEST_NAMES=%s", opts.test_name))
	}

	if len(parts) == 0 {
		return strings.clone("", allocator)
	}
	joined, join_err := strings.join(parts[:], " ", allocator)
	if join_err != nil {
		return strings.clone(base_flags, allocator)
	}
	return joined
}
