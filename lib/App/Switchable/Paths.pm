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


=head1 FUNCTIONS

=head2 home

Returns the C<HOME> environment variable. Croaks if unset.

=cut

sub home {
	state $home = $ENV{HOME} // croak "HOME environment variable is unset";
	return $home;
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
	
	# File already exists
	
	$path = $xdg->lookup_config_file($filename);
	return path($path) if defined $path;
	
	$path = path(home)->child('.switchable', $filename);
	return $path if $path->exists;
		
	# Default location
	
	$path = path($xdg->config_home)->child($filename);
	return $path if path($xdg->config_home)->exists;
	
	$path = path(home)->child('.switchable', $filename);
	return $path;
}

sub _find_aliases_file {
	my $filename = 'aliases.bash';
	my $path;
	
	# File already exists
	
	$path = $xdg->lookup_data_file($filename);
	return path($path) if defined $path;
	
	$path = path(home)->child('.switchable', $filename);
	return $path if $path->exists;
		
	# Default location
	
	$path = path($xdg->data_home)->child($filename);
	return $path if path($xdg->config_home)->exists;
	
	$path = path(home)->child('.switchable', $filename);
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
