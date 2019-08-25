package App::PRIME::Switchable;

use v5.020;

use Getopt::Long;
use Cwd qw<cwd realpath>;
use File::Path;
use List::Util qw<any none>;

use List::Gather;
use Path::Tiny;
use File::Which;

our $VERSION = '0.0.1';

# Assume $ENV{HOME} exists
if (not defined $ENV{HOME}) { die "No home dir" };
my $HOME = $ENV{HOME};


=head1 Functions

=cut

=head2 file_hierarchy

Returns whether we should be working using XDG directories or in our directory
C<~/.switchable>.

Returns 'xdg' or 'dot' (for C<~/.switchable>).
This is used by C<data_dir> and C<config_dir> to decide where those are.

=cut

sub file_hierarchy {
	if (path("$HOME/.switchable")->subsumes(__FILE__)) {
		return 'dot';
	}

	my $dir = $ENV{XDG_DATA_HOME} // "$HOME/.local/share";
	if (path($dir)->subsumes(__FILE__)) {
		return 'xdg';
	}

	my @outcomes = ('dot', 'xdg');

	my $env_var = $ENV{SWITCHABLE_HIER};
	if (defined $env_var) {
		if (any { $_ eq $env_var } @outcomes) {
			return $env_var;
		} else {
			die "Invalid hierarchy supplied from environment";
		}
	}

	die "Could not determine where the files are, try setting SWITCHABLE_HIER";
}

=head2 data_dir

Returns the data dir. It tries in order:

=over 2 

=item * C<$XDG_DATA_HOME/switchable> 

=item * C<$HOME/.local/share/switchable> 

=item * C<$HOME/.switchable>

=back

=head2 config_dir

Returns the config dir. It tries in order:

=over 2 

=item * C<$XDG_CONFIG_HOME/switchable> 

=item * C<$HOME/.config/switchable> 

=item * C<$HOME/.switchable>

=back

=cut

sub data_dir {
	my $dir;
	for (file_hierarchy) {
		if ($_ eq 'xdg') {
			$dir = $ENV{XDG_DATA_HOME} // "$HOME/.local/share";
			$dir .= '/switchable';
		} elsif ($_ eq 'dot') {
			$dir = "$HOME/.switchable";
		}
	}

	if (not -d $dir) { make_path$dir or die "Could not create data dir: $!" }

	return $dir;
}

sub config_dir {
	my $dir;	
	for (file_hierarchy) {
		if ($_ eq 'xdg') {
			$dir = $ENV{XDG_CONFIG_HOME} // "$HOME/.config";
			$dir .= '/switchable';
		} elsif ($_ eq 'dot') {
			$dir = "$HOME/.switchable";
		}
	}

	if (not -d $dir) { make_path $dir or die "Could not create config dir: $!" }

	return $dir;
}

our $ALIASES_FILE = path(data_dir)->child('aliases.bash');
our $REGEXES_FILE = path(config_dir)->child('switchable.conf');
our $BASH_FILE = path(data_dir)->child('switchable.bash');

=head2 aliased_commands

Reads C<$ALIASES_FILE> and returns the list of commands that are aliased.
Fails silently if the file doesn't exist.

=head2 matched_regexes

Reads C<$REGEXES_FILE> and returns the list of regexes to match against.
Fails silently if the file doesn't exist.

=cut

sub aliased_commands {
	if (not -f $ALIASES_FILE) { return () }

	my @lines = $ALIASES_FILE->lines({chomp => 1});

	# Remove comments and whitespace
	@lines = map { s/^\s+//; s/\s+$//; /^#/ ? () : $_ } @lines;

	my @commands = map { /^ alias \s+ (\w+) = /xx; $1 // () } @lines;

	return @commands;
}

sub matched_regexes {
	if (not -f $REGEXES_FILE) { return () }

	my @lines = $REGEXES_FILE->lines({chomp => 1});

	# Remove comments, whitespace and empty lines
	my @regexes = map { s/^\s+//; s/\s+$//; /^#/ ? () : $_ ? $_ : () } @lines;

	return @regexes;
}

=head2 get_command_name( $command )

Given a string that represents a command as displayed by C<history>, it returns
the invoked executable name, which is what bash stores in C<$0>.

The string can be multiline.

=cut

sub get_command_name {
	my ($command) = @_;
	my $name;

	# Remove whitespace
	$command =~ s/^\s+//s;
	$command =~ s/\s+$//s;

	my @parts;
	my $part;
	for ($command) {
		while (1) {
			# based on https://www.gnu.org/software/bash/manual/html_node/Quoting.html
			if (/ \G ' ( .*? ) ' /gcsxx) { $part = $1; }
			elsif (m{ \G " ( (?: \\ [" \\ \$ ` \n] | [^ "]) +) " }gcsxx) {
				$part = $1;
				$part =~ s/ \\ ( \$ | ` | " | \\ | \n ) /$1/gsxx;
			} elsif (/ \G ( (?: \w | (?: \\ .) )+ ) /gcsxx) {
				$part = $1;
				$part =~ s/ \\ (.) /$1/gsxx;
			} else {
				last;
			}

			push @parts, $part;
		}
	}

	$name = join '', @parts;

	return $name;
}

=head2 match_command( $command, @regexes )

It returns true if the command matches one of the regexes.

=cut

sub match_command {
	my ($command, @regexes) = @_;

	$command = get_command_name $ARGV[0];

	for my $regex (@regexes) {
		if ($command =~ /$regex/) { return 1 };
	}

	return 0;
}

=head2 add_alias_for( @execs )

Adds DRI_PRIME aliases of C<@execs> to the C<$ALIASES_FILE>

=head2 remove_alias_for( @execs )

Removes the DRI_PRIME aliases for C<@execs> in C<$ALIASES_FILE>

=cut

sub add_alias_for {
	my @execs = @_;

	foreach my $exec (@execs) {
		if (none {$exec eq $_} aliased_commands) {
			$ALIASES_FILE->append(qq[alias $exec='DRI_PRIME=1 $exec'\n]);
		}
	}
}

sub remove_alias_for {
	my @execs = @_;

	$ALIASES_FILE->edit_lines( sub {
		if (/^\s+#/) { return }
		if (/^ alias \s+ (\w+) = /xx && any {$1 eq $_} @execs) {
			$_ = undef;
		}
	});
}
=head1 Commands

=head2 grep_subcommand

Implements the grep subcommand. It acts on C<@ARGV>.

=cut

my $GREP_HELP = <<EOF;
Usage:
  switchable.pl grep [options] command_strings [...]

  Options:
    --regex, -r REGEX  Also match against this regex
	--verbose, -v      Print messages on error
    --help, -h         Print this help message
EOF

sub grep_subcommand {
	my $flag_help;
	my $verbose;
	my @commands;
	my @regexes;
	GetOptions (
		'help|h' => \$flag_help,
		'regex|r=s' => \@regexes,
		'verbose|v' => \$verbose
	);

	if ($flag_help) { print $GREP_HELP; exit; };

	if (!@ARGV) {
		say STDERR 'No command to match against' if $verbose;
		exit 1;
	}
	@commands = (@commands, @ARGV);


	# Reading config files
	if (not -f $REGEXES_FILE) {
		say STDERR 'No config file found' if $verbose;
		exit 1;
	}

	my @config_regexes = matched_regexes;

	@regexes = (@regexes, @config_regexes);
	@regexes = map { qr($_) } @regexes;


	# Main logic
	foreach my $command (@commands) {
		say $command if match_command($command, @regexes);
	}
}

=head2 add_subcommand

Implements the add subcommand. It acts on C<@ARGV>

=head2 remove_subcommand

Implements the remove subcommand. It acts on C<@ARGV>

=cut

my $ADD_HELP = <<EOF;
Usage:
  switchable.pl add [options] executable_names [...]

  Options:
    --help, -h         Print this help message
EOF

sub add_subcommand {
	my $flag_help;
	GetOptions (
		'help|h' => \$flag_help,
	);

	if ($flag_help) { print $ADD_HELP; exit; }

	my @executables = gather {
		foreach my $exec (@ARGV) {
			if (defined which $exec) {
				take $exec;
			} else {
				say STDERR "$exec is not a valid command or could not be found";
			}
		}
	};
	if (!@executables) { say STDERR 'No executables given, see --help'; exit 1; }

	add_alias_for (@executables);
}

my $REMOVE_HELP = <<EOF;
Usage:
  switchable.pl remove [options] executable_names [...]

  Options:
    --help, -h         Print this help message
EOF

sub remove_subcommand {
	my $flag_help;
	GetOptions (
		'help|h' => \$flag_help,
	);

	if ($flag_help) { print $REMOVE_HELP; exit; }

	my @executables = @ARGV;
	if (!@executables) { say STDERR 'No executables given, see --help'; exit 1; }

	remove_alias_for (@executables);
}

=head2 file_subcommand

Implements the file subcommand. It acts on C<@ARGV>

=cut

my $FILE_HELP = <<EOF;
Usage:
  switchable.pl file [options] ressource

Prints nothing on error unless verbose is set.

  Ressources:
    alias, aliases     Returns the file containing the aliases
    regex, regexes     Returns the file containing the regexes
    bash, bashrc       Returns the file sourced by .bashrc

  Options:
    --help, -h         Print this help message
    --verbose, -v      Print errors
EOF

sub file_subcommand {
	my $flag_help;
	my $verbose;
	GetOptions (
		'help|h' => \$flag_help,
		'verbose|v' => \$verbose,
	);

	if ($flag_help) { print $FILE_HELP; exit; }

	if (!@ARGV) { say STDERR "No ressource specified, see --help"; exit 1; }

	my $ressource = shift @ARGV;
	for ($ressource) {
		if    (/^alias/) { say $ALIASES_FILE }
		elsif (/^regex/) { say $REGEXES_FILE }
		elsif (/^bash/)  { say $BASH_FILE }
		else { say STDERR "Invalid ressource, see --help"; exit 1; }
	}
}

=head2 list_subcommand

Implements the list subcommand. It acts on C<@ARGV>

=cut

my $LIST_HELP = <<EOF;
Usage:
  switchable.pl list [options]

  Options:
    --help, -h         Print this help message
EOF

sub list_subcommand {
	my $flag_help;
	GetOptions (
		'help|h' => \$flag_help,
	);

	if ($flag_help) { print $LIST_HELP; exit; }

	for (aliased_commands) {
		say $_;
	}
}

=head2 man_subcommand

Implements the man subcommand. It acts on C<@ARGV>

=cut

my $MAN = <<EOF;
TODO
EOF

sub man_subcommand {
	print $MAN;
}

=head2 run

Called as C<App::PRIME::Switchable-E<gt>run> or C<App::PRIME::Switchable::run>,
it acts on C<@ARGV> and contains the main logic.

=cut

my $HELP = <<EOF;
Usage:
  switchable.pl [--help] <subcommand> <arguments>
  
  Subcommands:
    grep          Match a command against the configured regexes
    add           Add an alias
    remove        Remove an alias
    file          Get the configuration file paths
    list          List active aliases
    man           Print the manual
EOF

sub run {
	# Subcommand handling

	if (!@ARGV) { say "No subcommand given, see --help"; exit 1 }

	my $subcommand = shift @ARGV;
	for ($subcommand) {
		if    ($_ eq 'grep')    { grep_subcommand }
		elsif ($_ eq 'add')     { add_subcommand }
		elsif ($_ eq 'remove')  { remove_subcommand }
		elsif ($_ eq 'file')    { file_subcommand }
		elsif ($_ eq 'list')    { list_subcommand }
		elsif ($_ eq 'man')     { man_subcommand }
		elsif ($_ eq '--help' || $_ eq '-h') { print $HELP; exit }
		else { say "Invalid subcommand given: $subcommand, see --help"; exit 1 }
	}

	return 1;
}


1;
