use v5.20;
use feature 'refaliasing';
no warnings 'experimental::refaliasing';

use lib './lib';
use Test::More tests => 16;

require_ok 'App::PRIME::Switchable';

my @commands = (
	['exec',         'exec',  'simple'],
	['exec arg',     'exec',  'simple arg'],
	[' exec  arg',   'exec',  'leading space'],
	["\texec\targ",  'exec',  'tabs'],
	["exec\narg",    'exec',  'trailing newline'],
	[qq(e\\\nx\\\te\\ x), qq(e\nx\te x), 'escaped whitespace'],

	[q('quoted'),     'quoted',      'single quote'],
	[q('quoted '),    'quoted ',     'quoted space'],
	[qq('quo\nted'),  qq(quo\nted),  'quoted newline'],
	[q('quo\ted\n'),  q(quo\ted\n),  'quoted escapes'],
	[q('quo'ted),     'quoted',      'partially quoted'],
	[q('\\''),        q(\\),         'unescaped quote'],

	['"qquoted"', 'qquoted', 'qquoted'],
	[qq("qquo\\t\\ed"),  qq(qquo\\t\\ed),  'non-escaping backslash'],
	[qq("q\\\\uot\\\$\\`\\\ned"),  qq(q\\uot\$`\ned),  'escaping backslash']
);

foreach \my @v (@commands) {
	is( App::PRIME::Switchable::get_command_name($v[0]),  $v[1], $v[2]);
}
