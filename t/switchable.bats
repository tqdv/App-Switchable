@test "\"switchable\" status code is 2" {
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

@test "\"switchable --version\" status code is 0" {
	run ./switchable --version
	[ "$status" -eq 0 ]
}

@test "\"switchable --version\" displays a version string" {
	run ./switchable --version
	# Match v\d+.\d+.\d+
	[ -n "$( echo "$output" | grep -E "v[0-9]{1,}.[0-9]{1,}.[0-9]{1,}" )" ]
}
