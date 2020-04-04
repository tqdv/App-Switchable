@test "\"switchable run\" status code is 0" {
	run ./switchable run
	[ "$status" -eq 0 ]
}

@test "\"switchable run\" displays usage" {
	run ./switchable run
	[ -n "$( echo $output | grep "Usage" )" ]
}

@test "\"switchable run --help\" prints help" {
	run ./switchable run --help
	[ -n "$( echo "$output" | grep "Usage" )" ]
}

@test "\"switchable run --help\" mentions --help" {
	run ./switchable run --help
	[ -n "$( echo "$output" | grep -- "--help" )" ]
}

@test "\"switchable run --help\" mentions --driver" {
	run ./switchable run --help
	[ -n "$( echo "$output" | grep -- "--driver" )" ]
}

@test "\"switchable run --help\" mentions --expand" {
	run ./switchable run --help
	[ -n "$( echo "$output" | grep -- "--expand" )" ]
}

@test "\"switchable run echo \$DRI_PRIME\" prints the value of DRI_PRIME before execution" {
	expected=$DRI_PRIME
	run ./switchable run echo $DRI_PRIME
	[ "$output" = "$expected" ]
}

@test "switchable run \"--expand\" option works" {
	run ./switchable run --expand echo '$DRI_PRIME'
	[ "$output" = "1" ]
}

@test "switchable run \"--driver\" option works" {
	run ./switchable run --driver 3 --expand echo '$DRI_PRIME'
	[ "$output" = "3" ]
}

@test "switchable run \"-d\" option works" {
	run ./switchable run -d 3 --expand echo '$DRI_PRIME'
	[ "$output" = "3" ]
}
