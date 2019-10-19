package App::Switchable::Commands;

use feature qw<say state>;
use Getopt::Long;

use File::Which;
use List::Gather;

use App::Switchable::Utils qw< parse_xrandr >;

require Exporter;
our @ISA = qw<Exporter>;
our @EXPORT_OK = qw<get_command>;

=encoding utf8

=head1 NAME

App::Switchable::Commands

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This module implements all the subcommands. It is supposed to be a mixin for
L<App::Switchable>. That is why it uses methods from it.

=head1 FUNCTIONS

=cut

=head2 get_command( $name )

Returns a sub ref that handles the C<$name> subcommand. Returns C<undef>
otherwise.

=cut

# List of implemented commands
my @commands = qw<run preexec precmd>;

sub get_command {
	my $self = shift;
	my ($name) = @_;
	
	state %lookup;
	unless (%lookup) {
		foreach my $n (@commands) {
			$lookup{$n} = \&{ __PACKAGE__."::${n}_subcommand"};
		}
	}

	return $lookup{$name};
}


=head1 COMMANDS

=head2 $app->run_subcommand

Runs the command specified with the default shell

=cut

my $RUN_HELP = <<EOF;
Usage:
  switchable run <options>

Options:
  --help, -h           Display this help text
  --driver, -d STRING  The value of DRI_PRIME
EOF

sub run_subcommand {
	my $self = shift;

	my $val = 1;
	my $help;
	# Avoid consuming the switches belonging to the command to run
	Getopt::Long::Configure(qw<require_order passthrough>);
	GetOptions(
		"driver|d=s" => \$val,
		"help|h"     => \$help,
	);

	if ($help) { print $RUN_HELP; return }

	if (!@ARGV) { exit 2 }

	if ($self->command_already_ran) {
		# Do nothing
		# Exit with the command return code
		my $ret = $ENV{SWITCHABLE_RET} // 0;
		exit $ret;
		
	} else {
		# Modify env with perl, and call the command double-quoted to preserve
		# splitting and enable interpolation
		my $cmd =
			join ' ',
			map { q(") . ($_  =~ s/"/\\"/gr) . q(") }
			@ARGV;
		local $ENV{DRI_PRIME} = $val;

		exec $cmd;
	}
}


=head2 $app->preexec_subcommand

Receives as its first argument, the command to execute. It prints the commands
to prepare for execution or even executes the command directly.

TODO allow different value of DRI_PRIME

=head2 $app->precmd_subcommand

Cleans up the setup done in preexec.

=cut

# The bash code is generated here instead of written in the file to allow future
# modification of the bash commands based on context

sub preexec_subcommand {
	my $self = shift;

	my $command = shift @ARGV;
	print "echo .$command.;";
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
		print <<EOF;
if [ -n \${DRI_PRIME+x} ];
then
	export SWITCHABLE_DP_BAK=\$DRI_PRIME;
fi;
export DRI_PRIME=1;
EOF
	}

	if ($run_command) {
		print <<EOF
echo "Executing $run_command";
$run_command;
SWITCHABLE_RAN=1;
EOF
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

1;

__END__

=head1 ENVIRONMENT VARIABLES

=over 4

=item SWITCHABLE_RET – Return code of the command executed in the preexec hook

=back
