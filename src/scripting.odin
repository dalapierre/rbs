/*
	Shell/script process runner with live stdout/stderr
	(used by exec and user scripts).
*/
package rbs

import "core:fmt"
import "core:strings"
import "core:os"

/*
	Run a shell command string and stream its stdout/stderr.

	* script - Command line to execute (via bash -c on Linux)

	returns nil on success, or .Script_Error on failure
*/
run_script :: proc(script: string) -> Error {
	cmds: []string
	if ODIN_OS == .Linux {
		cmds = { "bash", "-c", script }
	} else {
		cmds = strings.split(script, " ")
	}

	p, start_err := os.process_start({
		command = cmds,
		stdout  = os.stdout,
		stderr  = os.stderr,
	})
	if ODIN_OS != .Linux {
		delete(cmds)
	}
	if start_err != nil {
		fmt.eprintfln("Script %s failed with %s", script, start_err)
		return .Script_Error
	}

	state, process_err := os.process_wait(p)
	if process_err != nil {
		fmt.eprintfln("Script %s failed with %s", script, process_err)
		return .Script_Error
	}

	if state.exit_code != 0 {
		fmt.eprintfln("Script exited with code: %d", state.exit_code)
		return .Script_Error
	}

	return nil
}
