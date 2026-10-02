// Tests for -target: platform strings and binary extensions.
package rbs

import "core:testing"

@(test)
test_get_platform_common_targets :: proc(t: ^testing.T) {
	testing.expect_value(t, get_platform(.amd64, .Linux), "linux_amd64")
	testing.expect_value(t, get_platform(.arm64, .Linux), "linux_arm64")
	testing.expect_value(t, get_platform(.amd64, .Windows), "windows_amd64")
	testing.expect_value(t, get_platform(.arm64, .Darwin), "darwin_arm64")
	testing.expect_value(t, get_platform(.amd64, .Darwin), "darwin_amd64")
}

@(test)
test_get_extension_by_os_and_mode :: proc(t: ^testing.T) {
	ext, err := get_extension(.Windows, .Executable)
	testing.expect(t, err == nil)
	testing.expect_value(t, ext, ".exe")

	ext, err = get_extension(.Windows, .Dynamic)
	testing.expect(t, err == nil)
	testing.expect_value(t, ext, ".dll")

	ext, err = get_extension(.Linux, .Executable)
	testing.expect(t, err == nil)
	testing.expect_value(t, ext, "")

	ext, err = get_extension(.Linux, .Dynamic)
	testing.expect(t, err == nil)
	testing.expect_value(t, ext, ".so")

	ext, err = get_extension(.Darwin, .Dynamic)
	testing.expect(t, err == nil)
	testing.expect_value(t, ext, ".dylib")

	ext, err = get_extension(.Unknown, .Executable)
	testing.expect(t, err == .Invalid_Extension)
	testing.expect_value(t, ext, "")
}
