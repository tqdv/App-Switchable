package App::Switchable::Utils;

require Exporter;
our @ISA = qw<Exporter>;
our @EXPORT_OK = qw< parse_xrandr >;

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


