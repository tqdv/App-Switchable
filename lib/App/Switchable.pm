package App::Switchable;

use v5.020;
use Getopt::Long;

require App::Switchable::Commands;  # Mixin
our @ISA = qw< App::Switchable::Commands >;

our $VERSION = '0.0.2';


=encoding utf8

=head1 NAME

App::Switchable

=head1 VERSION

v0.0.2

=head1 CONSTRUCTOR

=head2 ->new( \%config )

Creates the L<App::Switchable> object.

The C<%config> hash has a key C<hier> that is passed to
L<App::Switchable::Paths>.

=cut

sub new {
	my $class = shift;
	my $config = { @_ };

	bless {
		config => $config,
	}, $class;
}


=head1 METHODS

=head2 $app->config

Returns the configuration hashref.

=head2 $app->files

Returns the L<App::Switchable::File> object. (lazy)

=head2 $app->paths

Returns the L<App::Switchable::Paths> object. (lazy)

=head2 $app->command_already_ran

Returns whether the bash_preexec hook has already ran the command supplied to
C<switchable run>

=cut 

sub config {
	my $self = shift;

	return $self->{config};
}

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

sub paths {
	my $self = shift;

	state $req = 0;
	if (!$req++) {
		require App::Switchable::Paths;
		App::Switchable::Paths->import(qw< new_paths >);
	}

	$self->{paths} //= new_paths $self->config;

	return $self->{paths};
}

sub command_already_ran {
	my $self = shift;

	$self->{command_already_ran} //= $ENV{SWITCHABLE_RAN};

	return $self->{preexec};
}


=head2 $app->run

it acts on C<@ARGV> and contains the main logic.

=cut

my $HELP = <<EOF;
Usage:
  switchable [--help] <subcommand> <arguments>
  
  Subcommands:
    run   Enable the GPU for the supplied command
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

	if ($help) { print $HELP; exit 0 }
	if ($version) { print $0." v".$VERSION; exit 0 }

	# Subcommand handling
	if (!@ARGV) { say "No subcommand given, see --help"; exit 2 }
	my $subcommand = shift @ARGV;

	# Try ::Commands
	if (my $sub = $self->get_command($subcommand)) {
		$self->$sub();

	} else {
		say "Invalid subcommand given: \"$subcommand\", see --help";
		exit 1;
	}

	exit 0;
}


1;

__END__

=head1 EXIT CODES

=over 4

=item 2 – Missing argument

=item 1 – Bad argument

=item 0 – Nothing to report

=item -1 – TBD

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item SWITCHABLE_RAN - if the command supplied has already been ran

=back
