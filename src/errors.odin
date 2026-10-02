package rbs

import "base:runtime"
import "core:os"

RBS_Error :: enum {
    Script_Error,
    Invalid_Extension,
    Dependency_Does_Not_Exist,
    Command_Not_Found,
    Profile_Not_Found
}

Error :: union #shared_nil {
    os.Error,
    RBS_Error,
    runtime.Allocator_Error
}