#! perl

use strict;
use warnings;

use Test::More;

use Config;
use IPC::Open2 'open2';
use Devel::FindPerl 'find_perl_interpreter';

my $perl = find_perl_interpreter;

is(-s $perl, -s $Config{perlpath}, 'Found perl is same-sized as expected perl');

diag("$perl is not $Config{perlpath}, this may or may not be problematic") if $perl ne $Config{perlpath};

my $pid = open2(my($in, $out), $perl, qw/-MConfig=myconfig -e print -e myconfig/) or die "Could not start perl at $perl";
binmode $in, ':crlf' if $^O eq 'MSWin32';
my $ret = do { local $/; <$in> };
waitpid $pid, 0;
is($ret, Config->myconfig, 'Config of found perl equals current perl');

done_testing;
