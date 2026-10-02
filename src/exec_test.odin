// Tests for Builtin_Command and exec_cmd helpers.
package rbs

import "core:testing"

@(test)
test_odin_command_test_variant_exists :: proc(t: ^testing.T) {
	testing.expect(t, int(Builtin_Command.Test) != int(Builtin_Command.Build))
	testing.expect(t, int(Builtin_Command.Test) != int(Builtin_Command.Run))
	testing.expect(t, int(Builtin_Command.Build) != int(Builtin_Command.Run))
}
