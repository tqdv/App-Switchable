@test "\"switchable init\" sets SWITCHABLE_EXISTS (if preexec was found)" {
	run ./switchable init
	[ -n "$( echo "$output" | grep 'SWITCHABLE_EXISTS' )" ]
}

@test "\"switchable init\" sources the aliases file (if it exists)" {
	run ./switchable init
	[ -n "$( echo "$output" | grep 'SWITCHABLE_EXISTS' )" ]
}