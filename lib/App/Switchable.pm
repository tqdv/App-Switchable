package App::Switchable;

use v5.020;
use Getopt::Long;

use App::Switchable::Exits; # %EXIT
require App::Switchable::Commands;
require App::Switchable::Config;
require App::Switchable::Paths;
require App::Switchable::Preexec;
require App::Switchable::File;

our @ISA = qw<
	App::Switchable::Commands
	App::Switchable::Config
	App::Switchable::Paths
	App::Switchable::Preexec
	App::Switchable::File
>;

our $VERSION = v0.0.3;

=encoding utf8

=head1 NAME

App::Switchable

=head1 VERSION

v0.0.3

=head1 MIXINS

L<App::Switchable::Commands>
L<App::Switchable::Config>
L<App::Switchable::Paths>

=cut


=head1 CONSTRUCTOR

=head2 ->new( \%config )

Creates the L<App::Switchable> object.

The C<%config> hash has a key C<hier> that is passed to
L<App::Switchable::Paths>.

=cut

sub new {
	my $class = shift;
	my %config = @_;

	my $obj = bless {
		init => \%config
	}, $class;
	
	return $obj;
}


=head1 METHODS

=head2 $app->files

Returns the L<App::Switchable::File> object. (lazy)

=cut

sub files {
	my $self = shift;

	state $req = 0;
	if (!$req++) {
		require App::Switchable::File;
		App::Switchable::File->import(qw< new_filess >);
	}
	
	$self->{files} //= new_files $self->config, $self->paths;

	return $self->{files};
}


=head2 $app->run

it acts on C<@ARGV> and contains the main logic.

=cut

my $HELP = <<EOF;
Usage:
  switchable <subcommand> <arguments>
  switchable <subcommand> --help
  switchable --help | --version

  Subcommands:
    run             Enable the GPU for the supplied command
    reload-aliases  Reloads the aliases if possible
    show-config     Displays the loaded configuration
    xrandr          List DRI_PRIME values for each GPU
EOF

sub run {
	my $self = shift;

	# Arguments handling
	my ($help, $version);
	Getopt::Long::Configure(qw<require_order passthrough>);
	GetOptions(
		"help|h"    => \$help,
		"version"   => \$version,
	);
	Getopt::Long::Configure("default"); # Reset to default for subcommands

	if ($help)    { print $HELP; exit $EXIT{OK} }
	if ($version) { print $0." v".$VERSION; exit $EXIT{OK} }

	# Subcommand handling
	if (!@ARGV) { say "No subcommand given, see --help"; exit $EXIT{MISSING_ARG} }
	my $subcommand = shift @ARGV;

	# Try ::Commands
	if (my $sub = $self->get_command($subcommand)) {
		$self->$sub();

	} else {
		say "Invalid subcommand given: \"$subcommand\", see --help";
		exit $EXIT{BAD_ARG};
	}

	exit $EXIT{OK};
}


1;

__END__

=head1 EXIT CODES

=over 4

=item 3 — Bad IO

=item 2 – Missing argument

=item 1 – Bad argument

=item 0 – Nothing to report

=item -1 – Failure

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item SWITCHABLE_RAN - whether switchable has been run in a preexec hook.

=back
