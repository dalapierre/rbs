// Tests for CLI argument and flag parsing (get_cli / dispose_cli).
package rbs

import "core:testing"

@(test)
test_get_cli_args_and_flags :: proc(t: ^testing.T) {
	args := []string{
		"rune",
		"run",
		"debug",
		"-scn:main_menu",
		"--verbose",
		"-flag",
		"--define:FOO=bar",
	}

	cli := get_cli(args)
	defer dispose_cli(cli)

	testing.expect_value(t, len(cli.args), 2)
	testing.expect_value(t, cli.args[0], "run")
	testing.expect_value(t, cli.args[1], "debug")

	testing.expect_value(t, cli.flags["scn"], "main_menu")
	testing.expect_value(t, cli.flags["verbose"], "true")
	testing.expect_value(t, cli.flags["flag"], "true")
	testing.expect_value(t, cli.flags["define"], "FOO=bar")
}

@(test)
test_get_cli_skips_program_name :: proc(t: ^testing.T) {
	args := []string{"./rune", "build"}

	cli := get_cli(args)
	defer dispose_cli(cli)

	testing.expect_value(t, len(cli.args), 1)
	testing.expect_value(t, cli.args[0], "build")
	testing.expect_value(t, len(cli.flags), 0)
}

@(test)
test_get_cli_empty_args :: proc(t: ^testing.T) {
	cli := get_cli([]string{"rune"})
	defer dispose_cli(cli)

	testing.expect_value(t, len(cli.args), 0)
	testing.expect_value(t, len(cli.flags), 0)
}
