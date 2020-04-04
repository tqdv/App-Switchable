@test "\"switchable show-config\" status code is 0" {
	run ./switchable show-config
	[ "$status" -eq 0 ]
}

@test "\"switchable show-config\" displays the configuration file path" {
	run ./switchable show-config
	[ -n "$( echo "$output" | grep '/[^ /]*/' )" ]
}

@test "\"switchable show-config --help\" displays help" {
	run ./switchable show-config --help
	[ -n "$( echo "$output" | grep 'Usage' )" ]
}