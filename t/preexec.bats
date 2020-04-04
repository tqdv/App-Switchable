@test "\"switchable preexec\" sets SWITCHABLE_RAN" {
	run ./switchable preexec
	[ -n "$( echo "$output" | grep 'SWITCHABLE_RAN' )" ]
}

@test "\"switchable precmd\" unsets SWITCHABLE_RAN" {
	run ./switchable precmd
	[ -n "$( echo "$output" | grep 'SWITCHABLE_RAN' )" ]
}