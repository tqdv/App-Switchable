package App::Switchable::Commands;

use feature qw<say state>;
use Getopt::Long;
use Carp;

use List::MoreUtils qw< uniq >;

use App::Switchable::Exits; # %EXIT
use App::Switchable::Utils qw< parse_xrandr >;

require Exporter;
our @ISA = qw<Exporter>;
our @EXPORT_OK = qw<get_command>;


=encoding utf8

=head1 NAME

App::Switchable::Commands

=head1 SYNOPSIS

 require App::Switchable::Commands;
 our @ISA = qw< App::Switchable::Commands >;

 if (my $sub = $self->get_command( $command_name )) {
     $self->$sub();
 }

=head1 DESCRIPTION

This module implements all the subcommands. It is supposed to be a mixin for
L<App::Switchable>. That is why it uses methods from it.

Subcommands that require fast startup should be implemented in another module.

=head1 FUNCTIONS

=cut


=head2 get_command( $name )

Returns a sub ref that handles the C<$name> subcommand. Returns C<undef>
otherwise.

=cut

# List of implemented commands
our %commands = (
	init    => \&init_subcommand,
	run     => \&run_subcommand,
	preexec => \&preexec_subcommand,
	precmd  => \&precmd_subcommand,
	xrandr  => \&xrandr_subcommand,
	'show-config' => \&show_config_subcommand,
	'reload-aliases' => \&reload_aliases_subcommand,
);

sub get_command {
	my $self = shift;
	my ($name) = @_;
	
	return $commands{$name};
}

=head1 METHODS

=head2 $app->_reload_aliases_from($from)

Method called by C<< $app->reload_aliases_subcommand >> and C<< $app->preexec_subcommand >>.

C<$from> is either 'preexec' or 'command', and it controls how we print things out to the console.

=cut

sub _reload_aliases_from {
	my $self = shift;
	my ($from) = @_;
	
	sub _say {
		if ($from eq 'preexec') {
			say qq(echo "@_")
		} elsif ($from eq 'command') {
			say @_;
		}
	}
	
	$self->load_config_once;
	unless ($self->config_loaded) {
		_say "No configuration found, aborting.";
		exit $EXIT{BAD_IO};
	}
	
	# Tell the user which commands to unalias
	my ($found_alias, $old_aliases) = $self->read_old_aliases;
	my (@to_remove, @to_add);
	if ($found_alias) {
		my @old = $old_aliases->@*;
		my @new = $self->config->{alias}->@*;
		
		sub in_new { my $v = shift; grep {$_ eq $v } @new }
		@to_remove = grep { ! in_new($_) } @old;
		
		sub in_old { my $v = shift; grep {$_ eq $v } @old }
		@to_add = grep { ! in_old($_) } @new;
	}
	
	if (@to_remove) {
		_say "The following aliases have been removed: "
			. join(' ', map { qq('$_') } @to_remove)
			.". They are still loaded so unalias them by hand.";
	}
	
	$self->write_aliases;
	
	if (@to_add) {
		_say "New aliases written to '".$self->aliases_file.".";
	} else {
		_say "Aliases written to '".$self->aliases_file.".";
	}
}


=head1 COMMANDS

=head2 $app->init_subcommand

Prints out shell code to load aliases

=cut

sub init_subcommand {
	my $self = shift;
	
	$self->load_config_once;
	unless ($self->config_loaded) {
		say qq(echo "Failed to load switchable configuration file");
		exit $EXIT{BAD_IO};
	}
	
	# Load bash-preexec
	if (defined $self->preexec_path) {
		say "source ".$self->preexec_path;
		
		# Define hooks
		print <<'END';
sw_preexec() { eval "$( switchable preexec "$1" )"; }
sw_precmd() { eval "$( switchable precmd "$1" )"; }

preexec_functions+=(sw_preexec)
precmd_functions+=(sw_precmd)
END
	} else {
		say qq(echo "Could not find bash-preexec");
	}
	
	say qq(export SWITCHABLE_EXISTS=1);
	
	$self->write_aliases;
	my $alias = $self->aliases_file;
	if ($alias->exists) {
		say qq(source "$alias");
	}
}

=head2 $app->run_subcommand

Runs the command specified in C<@ARGV> with the default shell. Supports optional
shell expansion, and DRI_PRIME value.

=cut

my $RUN_HELP = <<EOF;
Usage:
  switchable run [options] <command>

Options:
  --help, -h             Display this help text
  --driver, -d <string>  The value of DRI_PRIME
  --expand               Pass the command as a string to eval
EOF

sub run_subcommand {
	my $self = shift;

	my %opts = ();
	# Avoid consuming the switches belonging to the command to run
	Getopt::Long::Configure(qw<require_order passthrough>);
	GetOptions(\%opts,
		"driver|d=s",
		"help|h",
		"expand",
	);

	$opts{driver} //= $self->config->{driver} // 1;

	if ($opts{help}) { print $RUN_HELP; return }


	if (!@ARGV) {
		# No command to run
		print $RUN_HELP;
		exit $EXIT{OK};
	}

	# Modify env with perl
	local $ENV{DRI_PRIME} = $opts{driver};

	# See docs/bash_splitting for details on how the arguments are handled

	if ($opts{expand}) {
		# use eval to perform shell expansion
		my $cmd = (join ' ', @ARGV) =~ s/'/'\\''/r;
		exec q(eval ') . $cmd . q(');

	} else {
		# Otherwise, keep the arguments as is
		exec { $ARGV[0] } @ARGV;
	}
}


=head2 $app->preexec_subcommand

Receives as its first argument, the command to execute. It prints out code
that modifies the appropriate environment variables.

The bash code is generated here instead of in a file to conditionally execute code based on configuration.

=head2 $app->precmd_subcommand

Cleans up the setup done in preexec.

=cut

# NB the output of this command is executed in the shell only when there's a command
# Make sure eveything is quoted properly !
sub preexec_subcommand {
	my $self = shift;

	say "export SWITCHABLE_RAN=1";

	my $command = shift @ARGV;
	# No warnings as this executed at every command entered in the shell
	unless (defined $command) {	exit 2 }
	
	# Process `switchable reload-aliases`
	if ($command =~ m{
		^ \s* (?: \Q$0\E | switchable ) # The command name or switchable
		\s+ reload-aliases  # followed by the `reload-aliases` subcommand
	}x) {
		$self->_reload_aliases_from('preexec');
		
		my $alias = $self->aliases_file;
		say qq(source "$alias") if $alias->exists;
		say qq(echo "Loaded new aliases in this shell");
	}

	if ($self->match_filter($command)) {# TODO detect pipes
		my $driver = $self->config->{driver} // 1;
	
		say qq{if [ -n "\${DRI_PRIME+x}" ]};
		say qq{then};
		say qq{	export SWITCHABLE_DP_BAK="\$DRI_PRIME"};
		say qq{fi};
		say qq{export DRI_PRIME=$driver};
	}
}

# NB the output of this command is executed in the shell
# NB precmd is executed even if there was nothing entered in the shell
sub precmd_subcommand {
	my $self = shift;

	print <<EOF;
unset SWITCHABLE_RAN
unset DRI_PRIME

if [ -n \${SWITCHABLE_DP_BAK+x} ]
then
	DRI_PRIME="\$SWITCHABLE_DP_BAK"
	unset SWITCHABLE_DP_BAK
fi
EOF
}


=head2 $app->show_config_subcommand

Display the loaded configuration.

=cut

sub show_config_subcommand {
	my $self = shift;

	my $help = <<END;
Usage: switchable show-config
Displays the loaded configuration.
END

	GetOptions(\%opts,
		"help",
	);
	
	if ($opts{help}) {
		print $help;
		exit $EXIT{OK};
	}
	
	unless($self->config_file->exists) { say "No configuration file found. Try creating ~/.config/switchable/config.json"; exit $EXIT{OK}; }
	say "Configuration file: ".$self->config_file;
	
	my $driver = $self->config->{driver} // "1 (not set)";
	say "Default gpu id: $driver";
	
	my @regexes = $self->config->{match}->@*;
	unless (@regexes) { say "No matches defined in the 'match' array" }
	else {
		say "Matches:";
		foreach my $match (@regexes) {
			say "  - $match";
		}
	}
	
	my @aliases = $self->config->{alias}->@*;
	unless (@aliases) { say "No aliases defined in the 'alias' array" }
	else {
		say "Aliases";
		foreach my $alias (@aliases) {
			say "  - $alias";
		}
	}
}

=head2 $app->reload_aliases_subcommand

Reloads the aliases by using the preexec hooks if available.

=cut

sub reload_aliases_subcommand {
	my $self = shift;
	
	if ($self->hook_ran) {
		# Do nothing as it has already been done in the preexec hook
		return;
	}
	
	$self->_reload_aliases_from('command');
}

=head2 $app->xrandr_subcommand

Displays DRI_PRIME values for each GPU by parsing the output of C<xrandr --listproviders>

=cut

sub xrandr_subcommand {
	my $self = shift;

	GetOptions(\%opts,
		"help",
	);

	if ($opts{help}) {
		say "Usage: switchable xrandr";
		say "";
		say "Prints the DRI_PRIME values for each GPU based on the output of `xrandr --listproviders`.";
		exit $EXIT{OK};
	}

	# Header
	say "DRI_PRIME: description";

	my @data = parse_xrandr();
	while (@data) {
		my $k = shift @data;
		my $v = shift @data;
		say "$k: $v";
	}
}


1;
