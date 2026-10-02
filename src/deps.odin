/*
	Dependency install into the profile output dir,
	plus recursive copy helpers for build assets.
*/
package rbs

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:text/regex"

Copy_Filter_Mode :: enum {
	Include,
	Exclude,
}

Copy_Option :: struct {
	pattern: string,
	mode:    Copy_Filter_Mode,
}

@(private="file")
Compiled_Copy_Filter :: struct {
	re:      regex.Regular_Expression,
	mode:    Copy_Filter_Mode,
	capture: regex.Capture,
}

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

/*
	Copy from into {profile.output}/{to}.

	* p - Profile whose output is the copy destination root
	* from - Source path (build-root relative or absolute)
	* to - Path under p.output; empty copies into p.output itself
	* opt - Optional name filter; nil copies every file; Include keeps
	  only base names matching pattern; Exclude skips matches

	returns nil on success, or an Error on path/filter/copy failure
*/
copy_to_output :: proc(p: Profile, from: string, to: string, opt: ^Copy_Option = nil) -> Error {
	abs_from, from_err := resolve_build_path(from)
	if from_err != nil do return from_err
	defer delete(abs_from)

	abs_output, out_err := resolve_build_path(p.output)
	if out_err != nil do return out_err
	defer delete(abs_output)

	dest: string
	dest_err: Error
	if to == "" {
		dest = strings.clone(abs_output)
	} else {
		dest, dest_err = filepath.join({abs_output, to}, context.allocator)
		if dest_err != nil do return dest_err
	}
	defer delete(dest)

	from_norm, from_alloc := strings.replace_all(abs_from, "\\", "/")
	defer if from_alloc do delete(from_norm)
	dest_norm, dest_alloc := strings.replace_all(dest, "\\", "/")
	defer if dest_alloc do delete(dest_norm)

	filter: ^Compiled_Copy_Filter
	compiled: Compiled_Copy_Filter
	if opt != nil {
		re, re_err := regex.create(opt.pattern, {.No_Capture})
		if re_err != nil {
			fmt.eprintfln("Invalid copy filter regex %q: %v", opt.pattern, re_err)
			return .Invalid_Copy_Filter
		}
		compiled.re = re
		compiled.mode = opt.mode
		compiled.capture = regex.preallocate_capture()
		filter = &compiled
	}
	defer if filter != nil {
		regex.destroy(compiled.re)
		regex.destroy(compiled.capture)
	}

	if err := process_copy(from_norm, from_norm, dest_norm, filter); err != nil {
		return err
	}

	log_dest := p.output
	log_dest_alloc := false
	if to != "" {
		joined, join_err := filepath.join({p.output, to}, context.allocator)
		if join_err == nil {
			log_dest = joined
			log_dest_alloc = true
		} else {
			log_dest = to
		}
	}
	defer if log_dest_alloc do delete(log_dest)

	fmt.printfln("[SUCCESS] Copy: %s -> %s", from, log_dest)
	return nil
}

@(private="file")
should_copy_file :: proc(filter: ^Compiled_Copy_Filter, path: string) -> bool {
	if filter == nil do return true

	name := filepath.base(path)
	_, matched := regex.match_with_preallocated_capture(filter.re, name, &filter.capture)
	switch filter.mode {
	case .Include: return matched
	case .Exclude: return !matched
	}
	return true
}

@(private="file")
process_copy :: proc(original_from: string, from: string, to: string, filter: ^Compiled_Copy_Filter) -> Error {
	if os.is_dir(from) {
		extra := strings.trim_prefix(from, original_from)
		new_dir, _ := strings.concatenate({to, extra})
		defer delete(new_dir)

		if !os.exists(new_dir) {
			err := os.make_directory_all(new_dir)
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
		defer os.file_info_slice_delete(files, context.allocator)

		for file in files {
			name, was_allocation := strings.replace(file.fullpath, "\\", "/", -1)
			defer if was_allocation do delete(name)

			copy_err := process_copy(original_from, name, to, filter)
			if copy_err != nil { return copy_err }
		}

		return nil
	}

	if !should_copy_file(filter, from) {
		return nil
	}

	extra := strings.trim_prefix(from, original_from)
	real_to := strings.concatenate({to, extra})
	defer delete(real_to)

	parent := filepath.dir(real_to)
	if parent != "" && !os.exists(parent) {
		if err := os.make_directory_all(parent); err != nil {
			fmt.eprintfln("Failed to create directory %s: %s", parent, err)
			return err
		}
	}

	copy_err := os.copy_file(real_to, from)
	if copy_err != nil {
		fmt.eprintfln("Failed to copy: %s", copy_err)
		return copy_err
	}

	return nil
}
