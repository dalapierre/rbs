package rcp

import "core:fmt"
import "core:crypto/hash"
import "core:os/os2"
import "core:path/filepath"

@(private="file")
CACHE_DIR :: ".rcp-cache"

check_cache :: proc(path: string, output: string) -> (is_cached: bool) {
    // create cache dir
    if !os2.exists(CACHE_DIR) {
        assert(os2.make_directory(CACHE_DIR) == nil, "Failed to create rcp cache directory")
    }

    // hash the path
    path_hash := hash.hash_string(.Insecure_MD5, path)
    defer delete(path_hash)
    s_hash := fmt.aprintf("%x", string(path_hash))
    defer delete(s_hash)
    full_hash_path := filepath.join({ CACHE_DIR, s_hash })
    defer delete(full_hash_path)
    
    file: ^os2.File
    defer os2.close(file)
    if !os2.exists(full_hash_path) do file, _ = os2.create(full_hash_path)
    else do file, _ = os2.open(full_hash_path)

    cached_content, some_err := os2.read_entire_file_from_file(file, context.allocator)
    assert(some_err == nil, "Failed to load cached content")

    path_content_hash := hash_file_content(path)

    if transmute(string)cached_content == transmute(string)path_content_hash &&
       os2.exists(output) {
        return true
    }

    write_err := os2.write_entire_file(full_hash_path, path_content_hash)

    return false
}

@(private="package")
hash_file_content :: proc(path: string) -> []byte {
    content, err := os2.read_entire_file_from_path(path, context.allocator)
    if err != nil do return {} // return err

    content_hash := hash.hash_bytes(.Insecure_MD5, content)

    return content_hash
}