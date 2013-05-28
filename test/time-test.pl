package Tests::Time;

use strict;
use warnings;

use lib '../lib';
use Time;

use Test::More tests => 32;

#---------------------

# 1. create new Time object

my $testcase = 'create a new Time object 2015-100-16:55:55.123';
my $time1_str = '2015-100-16:55:55.123';
my $time1 = new Time $time1_str;

is($time1, $time1_str, $testcase);


#---------------------

# 2. add 5 seconds

$testcase = 'add 5 seconds';
is($time1 + 5, '2015-100-16:56:00.123', $testcase);

#---------------------

# 3. subtract 10 seconds

$testcase = 'subtract 10 seconds';
is($time1 - 10, '2015-100-16:55:45.123', $testcase);

#---------------------

# 4. create a second Time object 1 day after the first

$testcase = 'create second Time object 2015-101-16:55:55.123';
my $time2_str = '2015-101-16:55:55.123';
my $time2 = new Time $time2_str;
is($time1 + 86400, $time2, $testcase);

#---------------------

# 5. subtract time 1 from 2 and verify 1 day difference

$testcase = 'subtract time 1 from 2 and verify 1 day difference';
is($time2 - $time1, 86400, $testcase);

#---------------------

# 6. check SC epoch

$testcase = 'check SC epoch';
my $epoch = Time->epoch();
is($epoch, '2000-001-00:00:00.000', $testcase);

#---------------------

# 7-9. check compare results

$testcase = "check compare results - $time1 to $time2";
is(Time::compare($time1, $time2), -1, $testcase);

$testcase = "check compare results - $time1 to $time1";
is(Time::compare($time1, $time1), 0, $testcase);

$testcase = "check compare results - $time2 to $time1";
is(Time::compare($time2, $time1), 1, $testcase);

#---------------------

# 10-13. check sort functionality

my $time3_str = '2030-365-03:21:00';
my $time3 = new Time $time3_str;
my @sort_results = sort { $a <=> $b } ($time2, $time3, $epoch, $time1);

$testcase = "check sort functionality - 1st entry = $epoch";
is($sort_results[0], $epoch, $testcase);

$testcase = "check sort functionality - 2nd entry = $time1";
is($sort_results[1], $time1, $testcase);

$testcase = "check sort functionality - 3rd entry = $time2";
is($sort_results[2], $time2, $testcase);

$testcase = "check sort functionality - 4th entry = $time3";
is($sort_results[3], $time3, $testcase);

#---------------------

# 14. check as_string

$testcase = "check as_string functionality - $time3 = $time3_str";
is($time3, $time3_str, $testcase);

#---------------------

# 15. check seconds

my $expected_diff = 978232860;
$testcase = "check seconds functionality - $time3 - $epoch = $expected_diff";
is($time3 - $epoch, $expected_diff, $testcase);

#---------------------

# 16. check mm/dd/yyyy hh:mm:ss format

$testcase = "check mm/dd/yyyy hh:mm:ss format for $time3";
is($time3->as_mmddyyyy_hhmmss, '12/31/2030 03:21:00', $testcase);

#---------------------

# 17. check hh:mm:ss format

$testcase = "check hh:mm:ss format for $time3";
is($time3->as_hhmmss, '03:21:00', $testcase);

#---------------------

# 18. check year

$testcase = "check year of $time3";
is($time3->year, '2030', $testcase);

#---------------------

# 19. check jday

$testcase = "check day of year of $time3";
is($time3->jday, '365', $testcase);


#---------------------

# 20-22. check is valid functionality

$testcase = "check that 2012-000-23:55:45 is not valid";
is(Time::is_valid('2012-000-23:55:45'), 0, $testcase);

$testcase = "check that 2012-366-23:55:45 is valid";
is(Time::is_valid('2012-366-23:55:45'), 1, $testcase);


$testcase = "check that 2013-366-23:55:45 is not valid";
is(Time::is_valid('2013-366-23:55:45'), 0, $testcase);

#---------------------

# 23-24. check is leap year functionality

$testcase = "check that 2016 is a leap year";
is(Time::is_leap_year('2016'), 1, $testcase);

$testcase = "check that 2018 is not a leap year";
is(Time::is_leap_year('2018'), 0, $testcase);

#---------------------

# 25-28. check get jdate list functionality

$testcase = "check the number of days in 2016 is 366";
my @days_in_2016 = Time::get_jdate_list('2016');
is(sum(\@days_in_2016), 366, $testcase);

$testcase = "check the number of days in 2015 is 365";
my @days_in_2015 = Time::get_jdate_list('2015');
is(sum(\@days_in_2015), 365, $testcase);

$testcase = "check the number of days in Feb 2016 is 29";
is($days_in_2016[1], 29, $testcase);

$testcase = "check the number of days in Feb 2015 is 28";
is($days_in_2015[1], 28, $testcase);

#---------------------

# 29-32. check override functionality

$testcase = "check $time2 > $time1";
ok($time2 > $time1, $testcase);

$testcase = "check $time2 ne $time1";
ok($time2 ne $time1, $testcase);

$testcase = "check order of operations absolute time";
is($time2 + 5 * 10 - 1, '2015-101-16:56:44.123', $testcase);

$testcase = "check order of operations number of seconds";
is($time2 - $time1 - 6 * 10, 86340, $testcase);

#---------------------

sub sum {
    my $list_ref = shift;
    my $sum = 0;
    $sum += $_ for (@{$list_ref});
    return $sum;
}