package rbs

import "base:runtime"
import "core:fmt"

@(private="package")
get_platform :: proc(arch: runtime.Odin_Arch_Type, os: runtime.Odin_OS_Type) -> (s_platform: string) {
    #partial switch os {
        case .Darwin:
            #partial switch arch {
                case .amd64:
                    s_platform = "darwin_amd64"
                case .arm64:
                    s_platform = "darwin_arm64"
                }
        case .Linux:
            #partial switch arch {
                case .i386:
                    s_platform = "linux_i386"
                case .amd64:
                    s_platform = "linux_amd64"
                case .arm64:
                    s_platform = "linux_arm64"
                case .arm32:
                    s_platform = "linux_arm32"
                case .riscv64:
                    s_platform = "linux_riscv64"
                }
        case .Windows:
            #partial switch arch {
                case .i386:
                    s_platform = "windows_i386"
                case .amd64:
                    s_platform = "windows_amd64"
                }
        case .FreeBSD:
            #partial switch arch {
                case .i386:
                    s_platform = "freebsd_i386"
                case .amd64:
                    s_platform = "freebsd_amd64"
                case .arm64:
                    s_platform = "freebsd_arm64"
                }
        case .NetBSD:
            #partial switch arch {
                case .amd64:
                    s_platform = "netbsd_amd64"
                case .arm64:
                    s_platform = "netbsd_arm64"
            }
        case .OpenBSD:
            #partial switch arch {
                case .amd64:
                    s_platform = "openbsd_amd64"
                }
        case .Haiku:
            #partial switch arch {
                case .amd64:
                    s_platform = "haiku_amd64"
                }
        case .Essence:
            #partial switch arch {
                case .amd64:
                    s_platform = "essence_amd64"
                }
        case .Freestanding:
            #partial switch arch {
                case .wasm32:
                    s_platform = "freestanding_wasm32"
                case .wasm64p32:
                    s_platform = "freestanding_wasm64p32"
                case .amd64:
                    s_platform = "freestanding_amd64_sysv"
                case .arm64:
                    s_platform = "freestanding_arm64"
                case .arm32:
                    s_platform = "freestanding_arm32"
                case .riscv64:
                    s_platform = "freestanding_riscv64"
                }
        case .WASI:
            #partial switch arch {
                case .wasm32:
                    s_platform = "wasi_wasm32"
                case .wasm64p32:
                    s_platform = "wasi_wasm64p32"
                }
        case .JS:
            #partial switch arch {
                case .wasm32:
                    s_platform = "js_wasm32"
                case .wasm64p32:
                    s_platform = "js_wasm64p32"
                }
        case .Orca:
            #partial switch arch {
                case .wasm32:
                    s_platform = "orca_wasm32"
                }
        case .Unknown:

    }
    
    return s_platform
}

@(private="file")
get_windows_ext :: proc(mode: runtime.Odin_Build_Mode_Type) -> (string, Error) {
    switch mode {
        case .Executable:
            return ".exe", nil
        case .Dynamic:
            return ".dll", nil
        case .Static:
            return ".lib", nil
        case .Object:
            return ".obj", nil
        case .Assembly:
            return ".asm", nil
        case .LLVM_IR:
            return ".ll", nil
    }

    return "", .Invalid_Extension
}

@(private="file")
get_unix_ext :: proc(mode: runtime.Odin_Build_Mode_Type) -> (string, Error) {
    switch mode {
        case .Executable:
            return "", nil
        case .Dynamic:
            return ".so", nil
        case .Static:
            return ".a", nil
        case .Object:
            return ".o", nil
        case .Assembly:
            return ".s", nil
        case .LLVM_IR:
            return ".ll", nil
    }

    return "", .Invalid_Extension
}

@(private="file")
get_mac_ext :: proc(mode: runtime.Odin_Build_Mode_Type) -> (string, Error) {
    switch mode {
        case .Executable:
            return "", nil
        case .Dynamic:
            return ".dylib", nil
        case .Static:
            return ".a", nil
        case .Object:
            return ".o", nil
        case .Assembly:
            return ".s", nil
        case .LLVM_IR:
            return ".ll", nil
    }

    return "", .Invalid_Extension
}

get_extension :: proc(os: runtime.Odin_OS_Type, mode: runtime.Odin_Build_Mode_Type) -> (string, Error) {
    ext: string
    ext_err: Error

    switch os {
        case .Windows:
            ext, ext_err = get_windows_ext(mode)
        case .Linux, .FreeBSD, .Essence, .OpenBSD, .NetBSD, .Haiku, .WASI, .JS, .Orca, .Freestanding:
            ext, ext_err = get_unix_ext(mode)
        case .Darwin:
            ext, ext_err = get_mac_ext(mode)
        case .Unknown:
            ext_err = .Invalid_Extension
    }

    if ext_err != nil {
        fmt.eprintfln("Build mode \"%s\" is not supported for architecture \"%s\"", os, mode)
        return "", ext_err
    }

    return ext, nil
}