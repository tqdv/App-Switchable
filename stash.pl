=head1 Functions

=cut

=head2 get_command_name( $command )

Given a string that represents a command as displayed by C<history>, it returns
the invoked executable name, which is what bash stores in C<$0>.

The string can be multiline.

=cut

sub get_command_name {
	my ($command) = @_;
	my $name;

	# Remove whitespace
	$command =~ s/^\s+//s;
	$command =~ s/\s+$//s;

	my @parts;
	my $part;
	for ($command) {
		while (1) {
			# based on https://www.gnu.org/software/bash/manual/html_node/Quoting.html
			# FIXME clarify handling of ` and $ in double quotes strings
			if (/ \G ' ( .*? ) ' /gcsxx) { $part = $1; }
			elsif (m{ \G " ( (?: \\ [" \\ \$ ` \n] | [^ "]) +) " }gcsxx) {
				$part = $1;
				$part =~ s/ \\ ( \$ | ` | " | \\ | \n ) /$1/gsxx;
			} elsif (/ \G ( (?: \w | (?: \\ .) )+ ) /gcsxx) {
				$part = $1;
				$part =~ s/ \\ (.) /$1/gsxx;
			} else {
				last;
			}

			push @parts, $part;
		}
	}

	$name = join '', @parts;

	return $name;
}
