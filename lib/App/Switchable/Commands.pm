package App::Switchable::Commands;

use feature qw<say state>;
use Getopt::Long;

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
my %commands = (
	run     => \&run_subcommand,
	preexec => \&preexec_subcommand,
	precmd  => \&precmd_subcommand,
	xrandr  => \&xrandr_subcommand,
);

sub get_command {
	my $self = shift;
	my ($name) = @_;
	
	return $commands{$name};
}


=head1 COMMANDS

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

	$opts{driver} //= 1;

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

Receives as its first argument, the command to execute. It prints the commands
to prepare for execution or even executes the command directly.

TODO allow different value of DRI_PRIME

=head2 $app->precmd_subcommand

Cleans up the setup done in preexec.

=cut

# The bash code is generated here instead of in the file to allow future
# modification of the bash commands by Switchable if needed
# Or simply put, I'm lazy and don't want to deal with loading the bash script

sub preexec_subcommand {
	my $self = shift;

	my %opts = ();
	# Avoid consuming the switches belonging to the command to run
	Getopt::Long::Configure(qw<require_order passthrough>);
	GetOptions(\%opts,
		"split",
	);

	if ($opts{split}) {
		...

	} else {

		my $command = shift @ARGV;
		print "echo .$command.";
		# No warnings as this executed at every command entered in the shell
		unless (defined $command) {	exit 2 }

		my $enable_dri;
		my $run_command; # The command to execute

		if ( # the command is `switchable run *`
			$command =~ m{
				\s*
				(?: \Q$0\E | switchable )  # The command name or switchable
				\s+
				run      # followed by the run subcommand
				\s+
				(.*)
			}x
		) {
			$run_command = $1;
			$enable_dri = 1;
		}
		elsif (0) {# $command in context matched a filter) { TODO
			$enable_dri = 1;
		}

		# FIXME variable interpolation is unsafe

		if ($enable_dri) {
			print
				qq{if [ -n \${DRI_PRIME+x} ];},
				qq{then};
				qq{	export SWITCHABLE_DP_BAK=\$DRI_PRIME;},
				qq{fi;},
				qq{export DRI_PRIME=1;},
			;
		}

		if ($run_command) {
			print
				qq{echo "Executing $run_command";},
				qq{$run_command;},
				qq{SWITCHABLE_RAN=1;},
			;
		}
	}

	# TODO look into DEBUG traps for DRI_PRIME to handle "export DRI_PRIME=1"
}

sub precmd_subcommand {
	my $self = shift;

	print <<EOF;
unset SWITCHABLE_RAN;
unset DRI_PRIME;

if [ -n \${SWITCHABLE_DP_BAK+x} ];
then
	DRI_PRIME=\$SWITCHABLE_DP_BAK;
	unset SWITCHABLE_DP_BAK;
fi
EOF
}


=head2 $app->xrandr_subcommand

Displays DRI_PRIME values for each GPU by parsing the output of C<xrandr --listproviders>

=cut

sub xrandr_subcommand {
	my $self = shift;

	# Avoid consuming the switches belonging to the command to run
	Getopt::Long::Configure(qw<require_order passthrough>);
	GetOptions(\%opts,
		"help",
	);

	if ($opts{help}) {
		say "Usage: switchable xrandr";
		say "";
		say "Prints the DRI_PRIME values for each GPU based on the output of `xrandr --listproviders`.";
		return $EXIT{OK};
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

__END__

=head1 ENVIRONMENT VARIABLES

=over 4

=item SWITCHABLE_RET – Return code of the command executed in the preexec hook

=back
