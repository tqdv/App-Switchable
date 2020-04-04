@test "\"switchable reload-aliases\" status code is 0" {
	run ./switchable reload-aliases
	[ "$status" -eq 0 ]
}

@test "\"switchable reload-aliases --help\" displays help" {
	run ./switchable reload-aliases --help
	[ -n "$( echo "$output" | grep 'Usage' )" ]
}

@test "\"switchable reload-aliases\" displays the aliases file" {
	run ./switchable run echo "$SWITCHABLE_RAN"
	[ -n "$output" ] && skip "preexec is enabled, retest it manually"
	
	run ./switchable reload-aliases --help
	[ -n "$( echo "$output" | grep '/[^ /]*/' )" ]
}