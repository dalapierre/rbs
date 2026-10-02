// Shared Error union and RBS_Error enum used across the package.
package rbs

import "base:runtime"
import "core:os"

RBS_Error :: enum {
    Script_Error,
    Invalid_Extension,
    Dependency_Does_Not_Exist,
    Command_Not_Found,
    Profile_Not_Found,
    Invalid_Test_Flag,
    Invalid_File_Flag,
    Invalid_Package_Flag,
}

Error :: union #shared_nil {
    os.Error,
    RBS_Error,
    runtime.Allocator_Error
}