package App::Switchable::Preexec;

use feature 'say';

=head1 NAME

App::Switchable::Preexec

=head1 SYNOPSIS

 # In App::Switchable
 require App::Switchable::Preexec;
 our @ISA = qw< App::Switchable::Preexec >;
 
 $self->match_filter('ls -l')

=head1 DESCRIPTION

Mixin for L<App::Switchable> that implements methods needed for preexec.

=head2 METHODS

=head2 $app->match_filter($command)

Returns whether the command matches any of the configured filters

=cut

sub match_filter {
	my $self = shift;
	my ($command) = @_;
	
	my @filters = $self->config->{match}->@*;
	
	foreach my $filter (@filters) {
		if ($command =~ /$filter/) {
			return 1;
		}
	}
	
	return 0;
}

1;