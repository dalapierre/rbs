package rbs

import "core:strings"

@(private="file")
DEFAULT_FLAG_VAL    :: "true"

@(private="package")
Parsed_Args :: struct {
    flags: map[string]string,
    args: [dynamic]string,
}

get_cli :: proc(args: []string, allocator := context.allocator) -> Parsed_Args {
    parsed := Parsed_Args{
        flags = make(map[string]string),
        args = make([dynamic]string),
    }
    
    for i := 1; i < len(args); i += 1 {
        token := args[i]
        
        if strings.has_prefix(token, "--") && len(token) > 2 {
            key := token[2:]
            
            colon_index := strings.index_byte(key, ':')
            if colon_index != -1 {
                actual_key := key[:colon_index]
                value := key[colon_index + 1:]
                parsed.flags[actual_key] = value
            } else {
                parsed.flags[key] = DEFAULT_FLAG_VAL
            }
        } else if strings.has_prefix(token, "-") && len(token) > 1 {
            without_dash := token[1:]
            colon_index := strings.index_byte(without_dash, ':')
            
            if colon_index != -1 {
                key := without_dash[:colon_index]
                value := without_dash[colon_index + 1:]
                parsed.flags[key] = value
            } else {
                parsed.flags[without_dash] = DEFAULT_FLAG_VAL
            }
        } else {
            append(&parsed.args, token)
        }
    }
    
    return parsed
}

dispose_cli :: proc(parsed: Parsed_Args) {
    delete(parsed.flags)
    delete(parsed.args)
}