package App::Switchable::Utils;

use Carp;

require Exporter;
our @ISA = qw<Exporter>;
our @EXPORT_OK = qw< parse_xrandr >;

=head1 FUNCTIONS

=head2 parse_xrandr

Assumes English output of C<xrandr --listproviders>.
Returns an array of flattened (DRI_PRIME value, GPU description) pairs.

=cut

sub parse_xrandr {
	my $s = qx{xrandr --listproviders};
	my @lines = split "\n", $s;

	# We use an array instead of a hash to preserver order
	my @data;
	for (@lines) {
		if (/Provider \  (\d+) : .*? name: \  (.*?) (?: ; | $)/xx) {
			push @data, $1, $2;;
		}
	}

	return @data;
}


=head2 parse_aliases( $file, \%options )

Given a L<Path::Tiny> filepath, this returns the list of commands that are
aliased.

You can optionally pass it an options hash reference.
Passing in C<< comment => 1 >> will comment all unrecognized entries. TODO
Passing C<< driver => 1 >> will make the function return an array of (command,
driver) arrayrefs.

=cut 

sub parse_aliases {
	my ($file, $opts) = @_;
	$opts //= {};

	unless ($file->is_file) {
		carp "Filepath $file is not a file";
		return;
	}

	my @lines = $file->lines({chomp => 1});

	my @commands;
	for (@lines) {
		# Trim whitespace
		s/^\s+//; s/\s+$//;

		# Skip comments and empty lines
		next if /^#/;
		next unless $_;

		/^ \s* alias \s+ (\w+) = .*? DRI_PRIME=(\S+) /x;

		my $val = $1;
		$val = [$1, $2]
			if $opts->{driver};

		push @commands, $val;
	}

	return @commands;
}
