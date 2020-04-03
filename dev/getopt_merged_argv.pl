use v5.20;
use Getopt::Long;
use Data::Dumper;

local @ARGV = ("--print", "--help --version", "--driver 2");

my %opts = ();
GetOptions(\%opts,
	"print",
	"help",
	"version",
	"driver=s",
);

print Dumper(\%opts);
