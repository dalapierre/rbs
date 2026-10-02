// Tests for shared Error union and RBS_Error variants.
package rbs

import "core:testing"

@(test)
test_rbs_error_variants_are_distinct :: proc(t: ^testing.T) {
	testing.expect(t, RBS_Error.Script_Error != RBS_Error.Invalid_Extension)
	testing.expect(t, RBS_Error.Command_Not_Found != RBS_Error.Profile_Not_Found)
	testing.expect(t, RBS_Error.Invalid_Test_Flag != RBS_Error.Invalid_File_Flag)
	testing.expect(t, RBS_Error.Invalid_Package_Flag != RBS_Error.Dependency_Does_Not_Exist)
	testing.expect(t, RBS_Error.Invalid_Copy_Filter != RBS_Error.Invalid_Package_Flag)
}

@(test)
test_error_union_shared_nil :: proc(t: ^testing.T) {
	err: Error
	testing.expect(t, err == nil)

	err = .Command_Not_Found
	testing.expect(t, err != nil)
	testing.expect(t, err == .Command_Not_Found)
}
