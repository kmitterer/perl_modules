package Tests::Globals;

use strict;
use warnings;

use lib '../lib';
use Globals;

use Test::More tests => 6;

#---------------------

# 1. create new Globals object

my $testcase = 'create a new Globals object';
our $CONFIG = new Globals './Config/test-globals.txt';
is(ref($CONFIG), 'Globals', $testcase);

#---------------------

# 2. verify access to a standard global

$testcase = 'check X-band WDT on-time timeout = 2400 secs';
is($CONFIG->get('XBAND_TX_MAX_ONTIME_SECS'), 2400, $testcase);

#---------------------

# 3. verify access to a global that is not specified is denied

$testcase = 'check that attempting to access fake_global throws an exception';
$@ = ''; # clear exceptions
eval { $CONFIG->get('fake_global') }; # trap exception
like($@, '/Internal error\: invalid global variable/i', $testcase);

#---------------------

# 4. verify direct access to a global is restricted

$testcase = 'check attempting to directly access the global throws an exception';
$@ = ''; # clear exceptions
$CONFIG->{'test2'} = 'this is a test';
my $val;
eval { $val = $CONFIG->get('test2') }; # trap exception
like($@, '/Internal error\: invalid global variable/i', $testcase);

#---------------------

# 5. verify the set method throws an exception if the name is invalid

$testcase = 'check that setting an invalid global name throws an exception';
$@ = ''; # clear exceptions
eval { $CONFIG->set('test3', 'this is a test') }; # trap the exception
like($@, '/Internal error\: invalid global variable/i', $testcase);

#---------------------

# 6. the global can be updated using the method

$testcase = 'check that a valid global name can be set properly';
$@ = ''; # clear exceptions
$CONFIG->set('XBAND_TX_MAX_ONTIME_SECS', 60);
$val = '';
is($CONFIG->get('XBAND_TX_MAX_ONTIME_SECS'), 60, $testcase);
