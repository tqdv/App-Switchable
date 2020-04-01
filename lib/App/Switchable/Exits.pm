package App::Switchable::Exits;

require Exporter;
our @ISA = qw<Exporter>;
our @EXPORT = qw< %EXIT >;

=head1 NAME

App::Switchable::Exits

=head1 SYNOPSIS

 use App::Switchable::Exits;

 exit $EXIT{OK};
 exit $EXIT{BAD_ARG};

=head1 DESCRIPTION

Exports the C<%EXIT> hash which maps readable codes to numbers.

=head1 VARIABLES

=head2 %EXIT

Exit codes hash. Please refer to the implementation for possible keys.

=cut

our %EXIT = (
	FAIL => -1,
	OK => 0,
	BAD_ARG => 1,
	MISSING_ARG => 2,
);


