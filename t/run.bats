@test "\"switchable run\" return code is 2" {
	run ./switchable run
	[ "$status" -eq 2 ]
}

@test "\"switchable run\" prints nothing" {
	run ./switchable run
	[ -z "$output" ]
}

@test "\"switchable run echo '\$DRI_PRIME'\" return code is 0" {
	run ./switchable run echo '$DRI_PRIME'
	[ "$status" -eq 0 ]
}

@test "\"switchable run echo '\$DRI_PRIME'\" prints 1" {
	run ./switchable run echo '$DRI_PRIME'
	[ "$output" = "1" ]
}


# With bash_preexec

# TODO
