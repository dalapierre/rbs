// Tests for path helpers and create_output directory creation.
package rbs

import "core:os"
import "core:path/filepath"
import "core:testing"

@(test)
test_create_output_when_directory_already_exists :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	out_dir, out_dir_err := filepath.join({tmp, "bin"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, os.make_directory(out_dir) == nil)
	testing.expect(t, os.is_dir(out_dir))

	// First call on an existing dir must succeed (no-op), not return .Exist.
	err := create_output(out_dir)
	testing.expect(t, err == nil)
	testing.expect(t, os.is_dir(out_dir))

	// Second call should also be fine (idempotent).
	err = create_output(out_dir)
	testing.expect(t, err == nil)
}

@(test)
test_create_output_creates_nested_directory :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	out_dir, out_dir_err := filepath.join({tmp, "a", "b", "c"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, !os.exists(out_dir))

	err := create_output(out_dir)
	testing.expect(t, err == nil)
	testing.expect(t, os.is_dir(out_dir))
}

@(test)
test_create_output_empty_is_noop :: proc(t: ^testing.T) {
	testing.expect(t, create_output("") == nil)
}

@(test)
test_ensure_trailing_slash :: proc(t: ^testing.T) {
	with := ensure_trailing_slash("bin/")
	defer delete(with)
	testing.expect_value(t, with, "bin/")

	without := ensure_trailing_slash("bin")
	defer delete(without)
	testing.expect_value(t, without, "bin/")
}

@(test)
test_resolve_build_path_absolute_unchanged :: proc(t: ^testing.T) {
	abs := "/tmp/rbs_abs_path"
	got, err := resolve_build_path(abs)
	defer delete(got)
	testing.expect(t, err == nil)
	testing.expect_value(t, got, abs)
}
