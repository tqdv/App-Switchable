@test "\"switchable xrandr\" status code is 0" {
	run ./switchable xrandr
	[ "$status" -eq 0 ]
}

@test "\"switchable xrandr\" lists at least one driver" {
	run ./switchable xrandr
	[ -n "$( echo "$output" | grep '[0-9]:' )" ]
}

@test "\"switchable xrandr --help\" displays help" {
	run ./switchable xrandr --help
	[ -n "$( echo "$output" | grep 'Usage' )" ]
}
