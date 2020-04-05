package App::Switchable::Config;

use feature qw<state say>;
use JSON::PP;
use Carp;
require App::Switchable::Paths;

=head1 NAME

App::Switchable::Config

=head1 SYNOPSIS

 # In App::Switchable
 require App::Switchable::Config
 our @ISA = qw< App::Switchable::Config >;
 
 $app->config;  # Get config hashref

=head1 DESCRIPTION

A mixin for App:Switchable that implements $app->config.

=cut

=head1 METHODS

=head2 $app->config

Returns the application config hashref

=cut

sub config {
	my $self = shift;
	
	$self->load_config_once;
	
	return $self{config};
}

=head2 $app->load_config

Reads the configuration file as JSON, and stores it. It carps on read error.

=head2 $app->load_config_once

Reads the configuration if it hasn't been read yet in the lifetime of the object.

=head2 $app->config_loaded

Whether the config has been successfully loaded or not.

=cut

sub load_config {
	my $self = shift;
	
	$self{config} //= {};
	
	my $string;
	eval {
		$string = $self->config_file->slurp;
		1;
	} or do {
		# Could not open file
		return;
	};
	
	eval {
		$self{config} = JSON::PP->new->relaxed->decode($string);
		$self{config_loaded} = 1;
		1;
	} or do {
		# Handle empty files
		if ($string =~ /^\s*$/) {
			$self{config_loaded} = 1;
			say STDERR "Configuration file is empty";
		} else {
			say STDERR "Could not parse configuration file as valid JSON: ".$self->config_file.".";
		}
	}
}

sub load_config_once {
	my $self = shift;
	
	state $once = 0;
	unless($once) {
		$once = 1;
		
		$self->load_config;
	}
}

sub config_loaded {
	my $self = shift;
	
	return $self{config_loaded};
}

=head2 hook_ran

Whether the preexec hook has already been run.

=cut

sub hook_ran {
	my $self = shift;
	
	return defined $ENV{SWITCHABLE_RAN};
}

1;
