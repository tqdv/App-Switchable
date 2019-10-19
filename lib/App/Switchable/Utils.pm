package App::Switchable::Utils;

require Exporter;
our @ISA = qw<Exporter>;
our @EXPORT_OK = qw< parse_xrandr >;

=head2 parse_xrandr

Assumes english output of xrandr.

=cut

sub parse_xrandr {
	my $s = qx{xrandr --listproviders};
	my @lines = split "\n", $s;

	my %h;
	for (@lines) {
		if (/Provider \  (\d+) : .*? name: \  (.*?) (?: ; | $)/xx) {
			$h{$1} = $2;
		}
	}

	return %h;
}

