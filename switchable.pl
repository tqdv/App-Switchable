#!/usr/bin/perl

use v5.26;
use File::Spec;

our $dir;

# Locate the lib
BEGIN {
	# Try 'xdg'
	$dir = $ENV{XDG_DATA_HOME} // "$ENV{HOME}/.local/share";
	$dir .= '/switchable';

	# Try 'dot'
	if (! -d $dir) {
		$dir = "$ENV{HOME}/.switchable";
	}

	# Fail
	if (! -d $dir) { die "Could not find library path" }
}

use lib "$dir/lib";

use App::PRIME::Switchable;

App::PRIME::Switchable->run;
