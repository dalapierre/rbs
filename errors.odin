package rbs

import "core:os/os2"

RBS_Error :: enum {
    Script_Error,
    Invalid_Extension,
    Dependency_Does_Not_Exist,
    Command_Not_Found,
    Profile_Not_Found
}

Error :: union #shared_nil {
    os2.Error,
    RBS_Error,
}