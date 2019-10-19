package App::Switchable::Paths;

use feature qw<state>;
use Carp;

use Path::Tiny;
use File::XDG::Systemd qw< xdg >;

require Exporter;
our @ISA = qw<Exporter>;
our @EXPORT_OK = qw< new_paths file_hierarchy >;


=head1 NAME

App::Switchable::Paths

=head1 SYNOPSIS

 use App::Switchable::Path qw< new_paths >;

 my $paths = new_paths;
 # or new_paths( hier => 'xdg' )

 $paths->aliases_file;
 $paths->data_dir;

=head1 DESCRIPTION

This module handles file paths. File creation and related things are
handled in L<App::Swithchable::File>.

=cut


=head1 FUNCTIONS

=head2 file_hierarchy

Returns whether we should be working using XDG directories or in our directory
C<~/.switchable>. It can be overriden by the C<SWITCHABLE_HIER> environment
variable if it is valid.

It detects the hierarchy by looking at the path of the current file, and
defaults to 'dot' (with a warning).

Returns 'xdg' or 'dot' (for C<~/.switchable>).
This is used by C<data_dir> and C<config_dir> to decide where those are.

=cut

sub file_hierarchy {
	my @outcomes = qw<dot xdg>;

	my $env_var = $ENV{SWITCHABLE_HIER};
	if (defined $env_var) {
		if (grep { $_ eq $env_var } @outcomes) {
			return $env_var;
		} else {
			carp "Invalid value \"$env_var\" assigned to SWITCHABLE_HIER";
		}
	}

	if (path($self->home."/.switchable")->subsumes(__FILE__)) {
		return 'dot';
	}

	my $dir = $ENV{XDG_LIB_HOME} // $self->home."/.local";
	if (path($dir)->subsumes(__FILE__)) {
		return 'xdg';
	}

	carp "Could not determine where the files are, defaulting"
		. " to ~/.switchable.\nTry setting SWITCHABLE_HIER";
	return 'dot';
}


=head1 CONSTRUCTOR

=head2 ->new( \%config )

Creates a new C<App::Switchable::File> object.

The (global) config hash can have a key C<hier> whose value is either
C<dot> or C<xdg>, which specifies where the files should be.

=head2 new_paths

Alias for the constructor.

=cut

sub new {
	my ($class) = shift;
	my ($config) = @_;

	my $hier = $config->{hier} // file_hierarchy;

	bless { hier => $hier }, __PACKAGE__;
}

sub new_paths {
	__PACKAGE__->new( @_ );
}


=head1 METHODS

=head2 $paths->home

Returns the home directorie or croak.

=cut

sub home {
	my $self = shift;

	state $home = $ENV{HOME} // croak "HOME environment variable is unset";

	return $home;
}


=head2 $paths->data_dir

=head2 $paths->config_dir

=head2 $paths->run_dir

=head2 $paths->lib_dir

Returns the directory as a L<Path::Tiny> object.

=cut

my @dirs = qw<data config run lib>;

# Initializes and returns the directory paths given one from @dirs as a
# Path::Tiny.
sub get_dir {
	my $self = shift;
	my ($name) = @_;

	state $dirs;
	unless ($dirs) {
		my $hier = $self->{hier};

		if ($hier eq 'xdg') {
			my $xdg = xdg( name => 'switchable' );
			$dirs = {
				config => path($xdg->config_home),
				data   => path($xdg->data_home),
				lib    => path($xdg->lib_home),
				run    => path($xdg->runtime_dir),
			};
		}
		elsif ($hier eq 'dot') {
			my $dotdir = path($self->home."/.switchable");
			$dirs = {
				config => $dotdir,
				data   => $dotdir,
				lib    => $dotdir,
				run    => $dotdir,
			};
		}
		else {
			croak "Unhandled hierarchy '$hier'";
		}
	}

	return $dirs->{$name} if exists $dirs->{$name};
}

# Returns a subroutine method given a string from @dirs.
sub gen_dir {
	my ($name) = @_;

	return sub {
		my $self = shift;
		return $self->get_dir($name);
	}
}

# Installs those submethods in the current package.
for my $name (@dirs) {
	*{__PACKAGE__."::${name}_dir"} = gen_dir $name;
}


=head2 $paths->aliases_file

=head2 $paths->regex_file

=head2 $paths->bash_file

=head2 $paths->command_file

Returns the specified filepath as L<Path::Tiny> object.

=cut

sub get_file {
	my $self = shift;
	my ($name) = @_;

	state $files;
	unless ($files) {
		$files = {
			alias   => $self->data_dir->child('aliases.bash'),
			regex   => $self->config_dir->child('regexes.conf'),
			bash    => $self->data_dir->child('switchable.bash'),
			command => $self->run_dir->child('command.bash'),
		}
	}

	return $files->{$name} if exists $files->{$name};
}

sub gen_files {
	my ($thing) = @_;

	return sub {
		my $self = shift @_;
		$self->get_file($thing);
	}
}

my %file_lookup= (
	aliases => 'alias',
	regexes => 'regex',
	bash    => 'bash',
	command => 'command',
);

while (my ($name, $val) = each %file_lookup) {
	*{__PACKAGE__."::${name}_file"} = gen_files $val;
}


1;
__END__

=head1 ENVIRONMENT VARIABLES

This module accesses the following environment variables:

=over 4

=item * HOME

=item * SWITCHABLE_HIER

=item * XDG_LIB_HOME

=back

=head1 DEPENDENCIES

=over 4

=item * L<Path::Tiny>

=item * L<File::XDG::Systemd>

=back
