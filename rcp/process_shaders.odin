package rcp

import "core:strings"
import "core:os/os2"
import "core:path/filepath"
import "core:fmt"
import rbs ".."

Shader_Type :: enum {
    Glsl,
    Hlsl
}

Shader_Format :: enum {
    SPIR_V
}

Shader_Info :: struct {
    path:   string,
    output: string,
    type:   Shader_Type,
    format: Shader_Format
}

process_shader :: proc(p: rbs.Profile, shader: Shader_Info) {
    if check_cache(shader.path, get_shader_output(p, shader)) do return
    
    switch shader.format {
        case .SPIR_V:
            process_spirv(p, shader)
    }
}

@(private="file")
process_spirv :: proc(p: rbs.Profile, shader: Shader_Info) {
    comp_cmd: string
    switch shader.type {
        case .Glsl:
            comp_cmd = "glslc"
        case .Hlsl:
            comp_cmd = "dxc"
    }


    output := get_shader_output(p, shader)
    log_processor(.Shader, shader.path, output)

    script := fmt.aprintf("%s %s -o %s", comp_cmd, shader.path, output)
    defer delete(script)
    assert(rbs.run_script(script) == nil, "Failed to process shader")
}

@(private="file")
get_shader_output :: proc(p: rbs.Profile, shader: Shader_Info) -> string {
    output_dir := filepath.dir(shader.output)

    real_out := strings.join({ p.output, output_dir }, "/")
    defer delete(real_out)

    if !os2.exists(real_out) {
        assert(os2.make_directory_all(real_out) == nil, "Failed to create content directory")
    }

    return strings.join({ p.output, shader.output }, "/")
}