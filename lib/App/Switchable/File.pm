package App::Switchable::File;

use Carp;

use App::Switchable::Paths qw< new_paths >;

require Exporter;
our @ISA = qw<Exporter>;
our @EXPORT_OK =
	qw<new_files parse_aliases parse_regexes add_aliases remove_aliases>;


=head1 NAME

App::Switchable::File

=head1 SYNOPSIS

 use App::Switchable::File qw< new_files add_aliases >;

 my $files = new_files( $config, $paths );
 $files->add_alias_for( 'glxgears', 'steam' );

 add_aliases( $file, { driver => 2 }, 'ls' );

=head1 DESCRIPTION

This module handles file creation, edition, and parsing.

=cut


=head1 CONSTRUCTOR

=head2 ->new( \%config, $paths )

Creates a new L<App::Switchable::File> object given a (global) config hash,
and a L<App::Switchable::Paths> object.

=head2 new_files

Alias to the constructor

=cut

sub new {
	my $class = shift;
	my ($config, $paths) = @_;

	bless { paths => $paths }, __PACKAGE__;
}

sub new_files {
	__PACKAGE__->new( @_ );
}

=head2 add_aliases( $file, \%options, @commands )

Given a L<Path::Tiny>, it adds an alias for C<$command> if it doesn't already
exist. If the file doesn't exist, it creates it.

The options hash can have a key C<driver> whose value is the value to be
assigned to C<DRI_PRIME>. It defaults to 1.

It doesn't verify whether the commands are valid.

=head2 remove_aliases( $file, \%options, @commands )

Given a L<Path::Tiny>, it removes aliases for commands. If the the file doesn't
exist, it carps.

This function doesn't have options, but it is left as a consistent interface
with C<add_aliases>.

=cut

sub add_aliases {
	my ($file, $opts, @commands) = @_;
	$opts //= {};
	my $driver = $opts->{driver} // 1;

	unless ($file->is_file) {
		$file->touchpath
			or croak "Could not create file $file";
	}

	my @previous = parse_aliases $file;

	foreach my $command (@commands) {
		if (!grep {$command eq $_} @previous) {
			$file->append(qq[alias $command='DRI_PRIME=$driver $command'\n]);
		}
	}
}

sub remove_aliases {
	my ($file, $opts, @commands) = @_;

	unless ($file->is_file) {
		carp "Aliases file $file is not a file";
		return;
	}

	$file->edit_lines( sub {
		if (/^\s+#/) { return }
		if (/^ alias \s+ (\w+) = /xx && grep {$1 eq $_} @commands) {
			$_ = undef;
		}
	});
}


=head1 METHODS

=head2 $files->paths

Convenience accessor to the L<App::Switchable::Paths> object.

=cut

sub paths {
	my $self = shift;

	return $self->{paths};
}


=head2 $files->aliased_command( \%options )

Returns a list of the aliased commands. The options hashref is passed as is
to C<parse_aliases>.

=head2 $files->matched_regexes( \%options )

Returns the list of regexes to match against. Options are passed to
C<parse_regexes>.

=cut

sub aliased_commands {
	my $self = shift;
	my ($opts) = @_;

	return parse_aliases $self->paths->aliases_file, $opts;
}

sub matched_regexes {
	my $self = shift;
	my ($opts) = @_;

	return parse_regexes $self->paths->regexes_file, $opts;
}


=head2 $files->add_alias_for( \%options, @execs )

Adds DRI_PRIME aliases of C<@execs> to the the aliases file. The options are
passed to C<add_aliases>.

=head2 $files->remove_alias_for( @execs )

Removes the DRI_PRIME aliases for C<@execs> in the aliases file. The options
are passed to C<remove_aliases>.

=cut

sub add_alias_for {
	my $self = shift;
	my ($opts, @commands) = @_;
	$opts //= {};

	add_aliases $self->paths->aliases_file, $opts, @commands;
}

sub remove_alias_for {
	my $self = shift;
	my ($opts, @commands) = @_;

	remove_aliases($self->paths->aliases_file, $opts, @commands);
}


1;
__END__

=head1 DEPENDENCIES

=over 4

=item * L<App::Switchable::Paths>

=back
