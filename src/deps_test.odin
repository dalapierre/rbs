// Tests for copy_to_output and dependency install helpers.
package rbs

import "core:os"
import "core:path/filepath"
import "core:testing"

@(test)
test_copy_file_into_profile_output :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	src_dir, src_dir_err := filepath.join({tmp, "assets"}, context.allocator)
	testing.expect(t, src_dir_err == nil)
	defer delete(src_dir)
	testing.expect(t, os.make_directory(src_dir) == nil)

	src_file, src_file_err := filepath.join({src_dir, "note.txt"}, context.allocator)
	testing.expect(t, src_file_err == nil)
	defer delete(src_file)
	testing.expect(t, os.write_entire_file(src_file, "hello") == nil)

	out_dir, out_dir_err := filepath.join({tmp, "bin"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, os.make_directory(out_dir) == nil)

	profile := Profile{
		output = out_dir,
		name   = "demo",
		entry  = "src",
		mode   = .Executable,
		os     = ODIN_OS,
		arch   = ODIN_ARCH,
	}

	err := copy_to_output(profile, src_file, "note.txt")
	testing.expect(t, err == nil)

	copied, copied_err := filepath.join({out_dir, "note.txt"}, context.allocator)
	testing.expect(t, copied_err == nil)
	defer delete(copied)
	testing.expect(t, os.exists(copied))

	content, read_err := os.read_entire_file_from_path(copied, context.allocator)
	defer delete(content)
	testing.expect(t, read_err == nil)
	testing.expect_value(t, string(content), "hello")
}

@(test)
test_copy_file_into_profile_output_renamed :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	src_dir, src_dir_err := filepath.join({tmp, "src"}, context.allocator)
	testing.expect(t, src_dir_err == nil)
	defer delete(src_dir)
	testing.expect(t, os.make_directory_all(src_dir) == nil)

	src_file, src_file_err := filepath.join({src_dir, "exec.odin"}, context.allocator)
	testing.expect(t, src_file_err == nil)
	defer delete(src_file)
	testing.expect(t, os.write_entire_file(src_file, "package main") == nil)

	out_dir, out_dir_err := filepath.join({tmp, "bin"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, os.make_directory(out_dir) == nil)

	profile := Profile{
		output = out_dir,
		name   = "demo",
		entry  = "src",
		mode   = .Executable,
		os     = ODIN_OS,
		arch   = ODIN_ARCH,
	}

	err := copy_to_output(profile, src_file, "exec_cool.odin")
	testing.expect(t, err == nil)

	renamed, renamed_err := filepath.join({out_dir, "exec_cool.odin"}, context.allocator)
	testing.expect(t, renamed_err == nil)
	defer delete(renamed)
	testing.expect(t, os.exists(renamed))

	original_name, original_err := filepath.join({out_dir, "exec.odin"}, context.allocator)
	testing.expect(t, original_err == nil)
	defer delete(original_name)
	testing.expect(t, !os.exists(original_name))

	content, read_err := os.read_entire_file_from_path(renamed, context.allocator)
	defer delete(content)
	testing.expect(t, read_err == nil)
	testing.expect_value(t, string(content), "package main")
}

@(test)
test_copy_directory_into_profile_output :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	src_dir, src_dir_err := filepath.join({tmp, "assets"}, context.allocator)
	testing.expect(t, src_dir_err == nil)
	defer delete(src_dir)
	testing.expect(t, os.make_directory(src_dir) == nil)

	nested, nested_err := filepath.join({src_dir, "nested"}, context.allocator)
	testing.expect(t, nested_err == nil)
	defer delete(nested)
	testing.expect(t, os.make_directory(nested) == nil)

	src_file, src_file_err := filepath.join({nested, "a.txt"}, context.allocator)
	testing.expect(t, src_file_err == nil)
	defer delete(src_file)
	testing.expect(t, os.write_entire_file(src_file, "nested") == nil)

	out_dir, out_dir_err := filepath.join({tmp, "bin"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, os.make_directory(out_dir) == nil)

	profile := Profile{
		output = out_dir,
		name   = "demo",
		entry  = "src",
		mode   = .Executable,
		os     = ODIN_OS,
		arch   = ODIN_ARCH,
	}

	err := copy_to_output(profile, src_dir, "copied")
	testing.expect(t, err == nil)

	copied, copied_err := filepath.join({out_dir, "copied", "nested", "a.txt"}, context.allocator)
	testing.expect(t, copied_err == nil)
	defer delete(copied)
	testing.expect(t, os.exists(copied))
}

@(test)
test_copy_to_output_exclude_by_regex :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	src_dir, src_dir_err := filepath.join({tmp, "src"}, context.allocator)
	testing.expect(t, src_dir_err == nil)
	defer delete(src_dir)
	testing.expect(t, os.make_directory(src_dir) == nil)

	keep, keep_err := filepath.join({src_dir, "main.odin"}, context.allocator)
	testing.expect(t, keep_err == nil)
	defer delete(keep)
	testing.expect(t, os.write_entire_file(keep, "package main") == nil)

	skip, skip_err := filepath.join({src_dir, "main_test.odin"}, context.allocator)
	testing.expect(t, skip_err == nil)
	defer delete(skip)
	testing.expect(t, os.write_entire_file(skip, "package main") == nil)

	out_dir, out_dir_err := filepath.join({tmp, "bin"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, os.make_directory(out_dir) == nil)

	profile := Profile{
		output = out_dir,
		name   = "demo",
		entry  = "src",
		mode   = .Executable,
		os     = ODIN_OS,
		arch   = ODIN_ARCH,
	}

	opt := Copy_Option{pattern = "_test", mode = .Exclude}
	err := copy_to_output(profile, src_dir, "out", &opt)
	testing.expect(t, err == nil)

	copied_keep, ck_err := filepath.join({out_dir, "out", "main.odin"}, context.allocator)
	testing.expect(t, ck_err == nil)
	defer delete(copied_keep)
	testing.expect(t, os.exists(copied_keep))

	copied_skip, cs_err := filepath.join({out_dir, "out", "main_test.odin"}, context.allocator)
	testing.expect(t, cs_err == nil)
	defer delete(copied_skip)
	testing.expect(t, !os.exists(copied_skip))
}

@(test)
test_copy_to_output_include_by_regex :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	src_dir, src_dir_err := filepath.join({tmp, "src"}, context.allocator)
	testing.expect(t, src_dir_err == nil)
	defer delete(src_dir)
	testing.expect(t, os.make_directory(src_dir) == nil)

	api_file, api_err := filepath.join({src_dir, "http_api.odin"}, context.allocator)
	testing.expect(t, api_err == nil)
	defer delete(api_file)
	testing.expect(t, os.write_entire_file(api_file, "package api") == nil)

	other, other_err := filepath.join({src_dir, "util.odin"}, context.allocator)
	testing.expect(t, other_err == nil)
	defer delete(other)
	testing.expect(t, os.write_entire_file(other, "package util") == nil)

	out_dir, out_dir_err := filepath.join({tmp, "bin"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, os.make_directory(out_dir) == nil)

	profile := Profile{
		output = out_dir,
		name   = "demo",
		entry  = "src",
		mode   = .Executable,
		os     = ODIN_OS,
		arch   = ODIN_ARCH,
	}

	opt := Copy_Option{pattern = "_api", mode = .Include}
	err := copy_to_output(profile, src_dir, "out", &opt)
	testing.expect(t, err == nil)

	copied_api, ca_err := filepath.join({out_dir, "out", "http_api.odin"}, context.allocator)
	testing.expect(t, ca_err == nil)
	defer delete(copied_api)
	testing.expect(t, os.exists(copied_api))

	copied_other, co_err := filepath.join({out_dir, "out", "util.odin"}, context.allocator)
	testing.expect(t, co_err == nil)
	defer delete(copied_other)
	testing.expect(t, !os.exists(copied_other))
}

@(test)
test_copy_to_output_invalid_regex :: proc(t: ^testing.T) {
	tmp, tmp_err := os.make_directory_temp("", "rbs_test_*", context.allocator)
	testing.expect(t, tmp_err == nil)
	defer os.remove_all(tmp)
	defer delete(tmp)

	src_file, src_file_err := filepath.join({tmp, "a.txt"}, context.allocator)
	testing.expect(t, src_file_err == nil)
	defer delete(src_file)
	testing.expect(t, os.write_entire_file(src_file, "x") == nil)

	out_dir, out_dir_err := filepath.join({tmp, "bin"}, context.allocator)
	testing.expect(t, out_dir_err == nil)
	defer delete(out_dir)
	testing.expect(t, os.make_directory(out_dir) == nil)

	profile := Profile{
		output = out_dir,
		name   = "demo",
		entry  = "src",
		mode   = .Executable,
		os     = ODIN_OS,
		arch   = ODIN_ARCH,
	}

	opt := Copy_Option{pattern = "[unterminated", mode = .Exclude}
	err := copy_to_output(profile, src_file, "a.txt", &opt)
	testing.expect_value(t, err, Error(.Invalid_Copy_Filter))
}
