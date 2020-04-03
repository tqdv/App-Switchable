package App::Switchable::Paths;

use feature qw<state>;
use Carp;

use Path::Tiny;
use File::XDG::Systemd qw< xdg >;

require Exporter;
our @ISA = qw< Exporter >;

=head1 NAME

App::Switchable::Paths

=head1 SYNOPSIS

 # In App::Switchable
 require App::Switchable::Paths;
 our @ISA = qw< App::Switchable::Paths >;
 
 $app->config_file;  # Get config file path

=head1 DESCRIPTION

This module handles file paths. File creation and related things are
handled in L<App::Switchable::File>.

=cut

=head1 VARIABLES

=head2 $xdg

L<File::XDG::Systemd> object for the app.

=cut

our $xdg = xdg( name => 'switchable');

=head2 %names

A hash of the filenames.

=cut

our %names = (
	config => 'config.json',
	alias => 'aliases.bash',
);

=head1 FUNCTIONS

=head2 home

Returns the C<HOME> environment variable. Croaks if unset.

=cut

sub home {
	state $home = $ENV{HOME} // croak "HOME environment variable is unset";
	return $home;
}

=head2 _prefered_location

C<_prefered_location> returns either 'xdg' or 'dot' based on existing files. Defaults to 'xdg'.
It will prefer the location where the configuration file is stored.

=cut

sub _prefered_location {
	my $x = path($xdg->config_home)->child($names{config})->exists;
	my $d = path($xdg->data_home)->child($names{alias})->exists;
	
	if ($d && !$x) { return 'dot' }
	return 'xdg';
}

=head2 _find_config_file

Finds an existing config file, or the path where it should be created.
Returns a L<Path::Tiny> object.

=head2 _find_aliases_file

Finds an existing aliases file, or the path where it should be created.
Returns a L<Path::Tiny> object.

=cut

sub _find_config_file {
	my $filename = 'config.json';
	my $path;
	
	my $loc = _prefered_location;
	if ($loc eq 'xdg') {
		$path = path($xdg->config_home)->child($filename);
	} elsif ($loc eq 'dot') {
		$path = path(home)->child('.switchable', $filename);
	}
	
	defined $path or croak "Could not decide where to put the config file";
	return $path;
}

sub _find_aliases_file {
	my $filename = 'aliases.bash';
	my $path;
	
	my $loc = _prefered_location;
	if ($loc eq 'xdg') {
		$path = path($xdg->data_home)->child($filename);
	} elsif ($loc eq 'dot') {
		$path = path(home)->child('.switchable', $filename);
	}
	
	defined $path or croak "Could not decide where to put the alias file";
	return $path;
}


=head1 METHODS

=head2 $app->config_file

Returns the configuration file path.

=head2 $app->aliases_file

Returns the aliases file path. Does not create it.

=cut

sub config_file {
	my $self = shift;
	
	state $config_file;
	$config_file //= _find_config_file;
	
	return $config_file;
}

sub aliases_file {
	my $self = shift;
	
	state $aliases_file;
	$aliases_file //= _find_aliases_file;
	
	return $aliases_file;
}

1;

=head1 ENVIRONMENT VARIABLES

This module accesses the following environment variables:

=over 4

=item * HOME

=back
