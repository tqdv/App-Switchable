@test "\"switchable xrandr\" exists... ish" {
	run ./switchable xrandr
	[ "$status" -ne 1 ]
}
