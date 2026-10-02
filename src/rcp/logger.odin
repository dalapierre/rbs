package rcp

import "core:fmt"

Processor_Type :: enum {
    Shader
}

log_processor :: proc(type: Processor_Type, path: string, out: string) {
    type_str := get_processor_type_str(type)
    fmt.printfln("[%s] Processing %s -> %s", type_str, path, out)
}

@(private="file")
get_processor_type_str :: proc(type: Processor_Type) -> string {
    switch type {
        case .Shader:
            return "Shader"
    }

    return ""
}
