// Tests for odin-test CLI flag parsing (-t/-f/-p) helpers.
package rbs

import "core:testing"

@(test)
test_parse_test_options_all_flags :: proc(t: ^testing.T) {
	flags := make(map[string]string)
	defer delete(flags)
	flags["t"] = "my_test"
	flags["f"] = "foo_test.odin"
	flags["p"] = "src"

	opts, err := parse_test_options(flags)
	testing.expect(t, err == nil)
	testing.expect_value(t, opts.test_name, "my_test")
	testing.expect_value(t, opts.file, "foo_test.odin")
	testing.expect_value(t, opts.package_path, "src")
}

@(test)
test_parse_test_options_bare_flags_are_invalid :: proc(t: ^testing.T) {
	flags_t := make(map[string]string)
	defer delete(flags_t)
	flags_t["t"] = "true"
	_, err := parse_test_options(flags_t)
	testing.expect(t, err == .Invalid_Test_Flag)

	flags_f := make(map[string]string)
	defer delete(flags_f)
	flags_f["f"] = "true"
	_, err = parse_test_options(flags_f)
	testing.expect(t, err == .Invalid_File_Flag)

	flags_p := make(map[string]string)
	defer delete(flags_p)
	flags_p["p"] = "true"
	_, err = parse_test_options(flags_p)
	testing.expect(t, err == .Invalid_Package_Flag)
}

@(test)
test_resolve_test_path_priority :: proc(t: ^testing.T) {
	opts := Test_Options{
		test_name    = "x",
		file         = "file_test.odin",
		package_path = "pkg",
	}

	path, file_mode := resolve_test_path(opts, "entry")
	testing.expect(t, file_mode)
	testing.expect_value(t, path, "file_test.odin")
	delete(path)

	opts.file = ""
	path, file_mode = resolve_test_path(opts, "entry")
	testing.expect(t, !file_mode)
	testing.expect_value(t, path, "pkg")
	delete(path)

	opts.package_path = ""
	path, file_mode = resolve_test_path(opts, "entry")
	testing.expect(t, !file_mode)
	testing.expect_value(t, path, "entry")
	delete(path)
}

@(test)
test_append_test_flags :: proc(t: ^testing.T) {
	flags := append_test_flags("-vet", Test_Options{test_name = "foo"}, true)
	defer delete(flags)
	testing.expect_value(t, flags, "-vet -file -define:ODIN_TEST_NAMES=foo")

	empty := append_test_flags("", {}, false)
	defer delete(empty)
	testing.expect_value(t, empty, "")
}
