#!/usr/bin/perl

use v5.20;

use FindBin;
use Getopt::Long;

chdir $FindBin::Bin;

my $HOME = $ENV{HOME} or die "No home found";

sub install_dot {
	my $target = '~/.switchable';

	qx{mkdir -p $target};
	qx{cp -r ./lib $target};
	qx{cp ./switchable.bash ./switchable.pl $target};
}

my $xdg_config = $ENV{XDG_CONFIG_HOME} // "$HOME/.config";
$xdg_config .= '/switchable';

my $xdg_data = $ENV{XDG_DATA_HOME} // "$HOME/.local/share";
$xdg_data .= '/switchable';

my $xdg_bin = "$HOME/.local/bin";

sub install_xdg {
	qx{mkdir -p $xdg_config};
	qx{mkdir -p $xdg_data};
	qx{mkdir -p $xdg_bin};

	qx{cp -r ./lib $xdg_data};
	qx{cp ./switchable.bash $xdg_data};
	qx{cp ./switchable.pl $xdg_bin};
}

my $hier;
GetOptions(
	'hierarchy|hier|h=s' => \$hier,
);

if    ($hier eq 'xdg') { install_xdg }
elsif ($hier eq 'dot') { install_dot }
elsif (not defined $hier) { install_xdg }
else { die "Invalid hierarchy value" }
