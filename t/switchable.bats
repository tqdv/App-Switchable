@test "\"switchable\" status code is 2 (missing argument)" {
	run ./switchable
	[ "$status" -eq 2 ]
}

@test "\"switchable\" points to '--help'" {
	run ./switchable
	[ -n "$( echo "$output" | grep "--help" )" ]
}

@test "\"switchable -h\" displays help" {
	run ./switchable -h
	[ -n "$( echo "$output" | grep "Usage" )" ]
}

@test "\"switchable --help\" displays help" {
	run ./switchable --help
	[ -n "$( echo "$output" | grep "Usage" )" ]
}

@test "\"switchable --help\" status code is 0" {
	run ./switchable --help
	[ "$status" -eq 0 ]
}

@test "\"switchable --help\" mentions --help" {
	run ./switchable --help
	[ -n "$( echo "$output" | grep -- "--help" )" ]
}

@test "\"switchable --help\" mentions --version" {
	run ./switchable --help
	[ -n "$( echo "$output" | grep -- "--version" )" ]
}

@test "\"switchable --help\" mentions run" {
	run ./switchable --help
	[ -n "$( echo "$output" | grep "run" )" ]
}

@test "\"switchable --help\" mentions reload-aliases" {
	run ./switchable --help
	[ -n "$( echo "$output" | grep "reload-aliases" )" ]
}

@test "\"switchable --help\" mentions show-config" {
	run ./switchable --help
	[ -n "$( echo "$output" | grep "show-config" )" ]
}

@test "\"switchable --help\" mentions xrandr" {
	run ./switchable --help
	[ -n "$( echo "$output" | grep "xrandr" )" ]
}

@test "\"switchable --version\" status code is 0" {
	run ./switchable --version
	[ "$status" -eq 0 ]
}

@test "\"switchable --version\" displays a version string" {
	run ./switchable --version
	# Match v\d+.\d+.\d+
	[ -n "$( echo "$output" | grep -E "v[0-9]{1,}.[0-9]{1,}.[0-9]{1,}" )" ]
}
