package Time;

use strict;
use warnings;

use Time::Local;
use overload ( '""' => 'as_string', '+' => 'add_secs', '-' => 'subtract_secs', 'cmp' => 'compare', '<=>' => 'compare', 'eq' => 'as_string', 'ne' => 'as_string', '==' => 'as_seconds', '>' => 'as_seconds', '>=' => 'as_seconds', '<' => 'as_seconds', '<=' => 'as_seconds', '!=' => 'as_seconds' );
use List::Util qw( sum );
use Carp qw( croak confess );

sub new {
	# accepts a properly formatted time and returns a corresponding instantiated Time object
    my $class = shift;
    my $timetag = shift;
    confess "Invalid timetag $timetag. The required format is yyyy-ddd-hh:mm:ss.sss where yyyy = year, ddd = day of year (Julian day), and hh:mm:ss.sss is UTCG time" unless is_valid($timetag);

    my $self = {};
    bless $self, $class;
    $self->{-timetag} = $timetag; # private: yyyy-ddd-hh:mm:ss.sss format time
    
    return $self;    
}

sub epoch {
	# returns the system epoch as a Time object
    my $class = shift;
    return $class->new('2000-001-00:00:00.000');
}

sub add_secs {
    # returns a new Time object set to timetag + seconds
    my ($self, $numsecs) = @_;
    return new Time convert_seconds_to_timetag($self->as_seconds() + $numsecs);
}

sub subtract_secs {
    # returns the difference in seconds (if a Time object is specified) or 
    # a new Time object corresponding to the modified absolute time if a (if a Time object is not specified) 
    my ($self, $numsecs) = @_;
    
    my $value;
    if (ref($numsecs) eq 'Time') {
        $value = $self->as_seconds() - $numsecs->as_seconds();
    } else {
        $value = $self->add_secs(-$numsecs);
    }

    return $value;
}

sub compare {
    # returns 1, 0, or -1 used by sorting routine (see Perl sort for details)
    my ($first, $second) = @_;
    
    unless (UNIVERSAL::isa($second, 'Time')) {
        confess "Can only compare two Time objects, not $second";
    }
    
    return ($first->as_seconds() <=> $second->as_seconds());
}

sub as_string {
    # alternate timetag accessor
    my $self = shift;
    return $self->timetag();
}

sub as_seconds {
    # returns the timetag converted to seconds from epoch
    my $self = shift;
    my ($mon, $mday, $year) = split /\//, $self->as_mmddyyyy();
    my ($hour, $min, $sec_subs) = split /\:/, $self->as_hhmmss();
    
    # convert to convention used by timelocal
    $year -= 1900; # number of years since 1900
    $mon -= 1; # month is zero indexed
    my ($sec, $subsec) = split /\./, $sec_subs;
    $subsec = 0 unless (defined $subsec and $subsec);
    $subsec = "0.$subsec";
    $subsec = sprintf "%.3f", $subsec;

    my $numseconds = timegm(int($sec), int($min), int($hour), $mday, $mon, $year);
    return $numseconds + $subsec;
}

sub as_mmddyyyy_hhmmss {
    # returns the timetag in "mm/dd/yyyy hh:mm:ss.sss" format
    my $self = shift;
    
    my ($year, $jday, $hhmmss) = split /\-/, $self->timetag();

    $jday = int($jday);
    my @jdates = get_jdate_list($year);

    my $mon;
    for ($mon = 0; $mon <= 11; $mon++) {
        last if ( sum(@jdates[0..$mon]) >= $jday);
    }
    my $mmddyyyy = "1/$jday/$year";
    $mmddyyyy = $mon + 1 . "/" . ($jday - sum(@jdates[0..($mon-1)])) . "/" . $year if ($mon >= 1);

    return "$mmddyyyy $hhmmss"; # mm/dd/yyyy format
}

sub as_mmddyyyy {
    # returns the timetag in mm/dd/yyyy format
    my $self = shift;
    my ($mmddyyyy, $hhmmss) = split /\s+/, $self->as_mmddyyyy_hhmmss();
    return $mmddyyyy;
}

sub as_hhmmss {
    # returns the timetag in hh:mm:ss.sss format
    my $self = shift;
    my ($mmddyyyy, $hhmmss) = split /\s+/, $self->as_mmddyyyy_hhmmss();
    return $hhmmss;
}

sub timetag {
    # returns the timetag base format
    my $self = shift;
    return $self->{-timetag};
}

sub year {
    # returns year entry from timetag base format
    my $self = shift;
    my ($year, $jday) = split /\-/, $self->timetag();
    return $year;
}

sub jday {
    # returns day of year (Julian day) entry from timetag base format
    my $self = shift;
    croak "Can't call without a caller $self" unless (defined $self and $self and ref($self));
    my ($year, $jday) = split /\-/, $self->timetag();
    return $jday;
}

sub convert_seconds_to_timetag {
    # accepts seconds since epoch and returns corresponding time in friendly jday format
    my $sec_subsecs = shift;
    my ($secs, $subsecs) = split /\./, $sec_subsecs;
    $subsecs = 0 unless (defined $subsecs and $subsecs);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = gmtime($secs);
    $year += 1900;
    my $doy = sprintf "%03d", $yday + 1;
    my $hhmmss = sprintf "%02d:%02d:%02d", ($hour, $min, $sec);
    #$subsecs = sprintf "%.3f", $subsecs;
    
    return "$year\-$doy\-$hhmmss\.$subsecs";
}

sub is_valid {
    # determine whether the input timetag is in a valid format (0 = invalid, 1 = valid)
    my ($year, $jday, $hhmmss) = split /\-/, shift; # yyyy-ddd-hh:mm:ss.sss
    
    my $is_valid = 1;
    
    # test for valid year
    $is_valid = 0 unless ($year =~ m/^\d+$/ and $year >= 2000 and $year < 2113 ); # launched 2/11/2013, 1/1/2000 used as uninitialized default
    
    # test for valid julian day
    my $maxdays = 365;
    $maxdays = 366 if ( $is_valid and is_leap_year($year) ); #only pass $year into is_leap_year if it passed the validity test above
    $is_valid = 0 unless ($jday =~ m/^\d+$/ and int($jday) > 0 and int($jday) <= $maxdays);

    my ($hour, $min, $secs) = split /\:/, $hhmmss;
    $is_valid = 0 unless ($hour =~ m/^\d+$/ and int($hour) >= 0 and int($hour) < 24);
    $is_valid = 0 unless ($min =~ m/^\d+$/ and int($min) >= 0 and int($min) < 60);
    $is_valid = 0 unless ($secs =~ m/^\d+\.?\d+$/ and int($secs) >= 0 and int($secs) < 60);

    return $is_valid;
}

sub is_leap_year {
    # returns boolean indicating whether the input year is a leap year (0 = no, 1 = yes)
    my $year = shift;
    my $is_leap_year = 0; # default to no
    $is_leap_year = 1 if ($year%4 == 0); # leap years are evenly divisible by 4 (2012, 2016, 2020, etc.)
    return $is_leap_year;
}

sub get_jdate_list {
    # accepts a year and returns the corresponding list of number of days in each month starting with January
    my $year = shift;
    my @jdate = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    $jdate[1] = 29 if ( is_leap_year($year) ); #account for leap years
    return @jdate;    
}


1;

__END__

=head1 NAME

Time - provides friendly time modification and comparison methods

=head1 SYNOPSIS

Provides methods to create an absolute time object and add and subtract seconds, 
compare one time to another, calculate the difference between two times and 
print (and debug) in a friendly format.

=head1 DESCRIPTION

This class is used by scripts and modules that are required to work relative to an absolute 
time and calculate offset times, compare times to one another, or calculate the difference 
between two times.

Note: that the base time format used by this class is yyyy-doy-hh:mm:ss.sss
where yyyy = year, doy = the integer day of year (001 -> Jan 1), hh = hours, 
mm = minutes, ss = seconds, and sss = milliseconds.

=head1 AUTHOR

Kent Mitterer

=cut
