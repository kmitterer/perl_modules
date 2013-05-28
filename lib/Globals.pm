package Globals;

use strict;
use warnings;

use Carp qw( confess );

sub new {
	# accepts a config filename and returns a globals object initialized to the values contained in the file
    my $class = shift;
    my $file = shift; # formatted config file containing global variable definitions
    my $self = {};
    bless $self, $class;

    # read the config settings from the file
    open GLOBAL, "<$file" or die "Cannot open file $file: $!";
    my @rows = <GLOBAL>;
    close GLOBAL;
    
    # and write each entered item to the global variable object
    foreach my $entry (@rows) {
        next if ($entry =~ m/^#/);
        chomp $entry;
        my ($key, $value) = split /\=/, $entry;
        $key =~ s/\s+//g;
        $value =~ s/\s+//g;
	    $self->{"$key"} = $value;
	    push @{$self->{"_valid_globals"}}, $key; # and add the globals name the list of valid items
    }
    return $self;
}

sub get {
	# accepts a name contained in the globals file and returns its value (note: names must be valid)
    my $self = shift;
    my $key = shift;
    # protect against calls to get the value of an invalid name
    confess "Internal Error: Invalid global variable $key specified. $key not found. Did someone change the Global_Config_Settings file?" unless (grep {$_ eq $key} @{$self->{"_valid_globals"}});
    return $self->{"$key"};
}

sub set {
	# accepts a name contained in the globals file and new value and sets the name to the specified value (note: names must be valid)
    my $self = shift;
    my $key = shift;
    my $value = shift;
    # protect against calls to set te value of an invalid name
    # note: set does allow you change the value of an existing global, just can't add a new global
    confess "Internal Error: Invalid global variable $key specified. $key not found. Did someone change the Global_Config_Settings file?" unless (grep {$_ eq $key} @{$self->{"_valid_globals"}});
    $self->{"$key"} = $value;
}

1;

__END__

=head1 NAME

Globals - provides support for friendlier global variables

=head1 SYNOPSIS

Provides methods to create and access a global variable hash reference from a formatted 
config file.

=head1 DESCRIPTION

The config file is specified in the new call. The config file is formatted as 
a simple text file of rows, each containing NAME=VALUE entries. Comments are s
pecified with a leading #. Note that calls to invalid names (names that do not 
occur in the config file) will throw an exception indicating a bad name entry
at run-time to provide fail early support.

=head1 AUTHOR

Kent Mitterer

=cut
