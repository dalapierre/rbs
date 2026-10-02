// Tests for run_script process execution.
package rbs

import "core:testing"

@(test)
test_run_script_success :: proc(t: ^testing.T) {
	err := run_script("true")
	testing.expect(t, err == nil)
}

@(test)
test_run_script_nonzero_exit :: proc(t: ^testing.T) {
	err := run_script("false")
	testing.expect(t, err == .Script_Error)
}
